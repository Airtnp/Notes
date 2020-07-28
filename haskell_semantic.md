# Semantic Reading

## Miscs

* `AST.Unmarshal ==> TS`





## Semantic



## AST



### GenerateSyntax

* `debugPrefix :: (String, Named) -> String`: just prefix symbols names
  * add `_` to `Anonymous` symbols

* `astDeclarationForLangauge`: 

  * Derive Haskell datatypes from a language and its `node-types.json` file

  * > Datatypes will be generated according to the specification in the `node-types.json` file, with anonymous leaf types defined as synonyms for the 'Token' datatype.
    >
    > Any datatypes among the node types which have already been defined in the module where the splice is run will be __skipped__, allowing __customization__ of the representation of parts of the tree. Note that this should be used sparingly, as it imposes extra maintenance burden, particularly when the grammar is changed. 
    >
    > This may be used to e.g. parse literals into Haskell equivalents (e.g. parsing the textual contents of integer literals into `Integer`s), and may require defining `TS.UnmarshalAnn` or `TS.SymbolMatching` instances for (parts of) the custom datatypes, depending on where and how the datatype occurs in the generated tree, in addition to the usual 'Foldable', 'Functor', etc. instances provided for generated datatypes.

  * ```haskell
    -- location :: Q Loc -- TH provides source path
    -- loc_filename :: Loc -> String
    -- getCurrentDirectory :: IO FilePath -- System.Directory provides `getcwd`
    -- takeDirectory :: FilePath -> FilePath -- System.FilePath.Posix provides `dirname`
    -- `(</>) :: FilePath -> FilePath -> FilePath` -- System.FilePath.Posix provides `join`
    -- eitherDecodeFileStrict' :: FromJson a => FilePath -> IO (Either String a) -- deserialized JSON value from a file, parse+conversopm immediately  (Data.Aeson), note that success is `Right` (AST.Deserialize.Datatype, which is a FromJSON instance)
    -- either :: (a -> c) -> (b -> c) -> Either a b -> c -- just case expansion, match/case in operational semantics
    -- pure :: forall (f :: * -> *) a. Applicative f => f a -- Applicative lift
    -- fail :: forall (m :: * -> *) a. MonadFail m => String -> m a (Control.Monad.Fail)
    -- getAllSymbols :: Ptr TS.Language -> IO [(String, Named)] (`Named` defined in `Ast.Deserialize`)
    -- stringL :: String -> Lit -- string -> literal
    -- litE :: Lit -> ExpQ -- literal -> expression
    -- listE :: [ExpQ] -> ExpQ -- list of exprs -> expr
    -- input :: [DataType]
    -- syntaxDatatype :: Ptr Ts.Language -> [(String, Named)] -> Datatype -> Q [Dec]
    -- traverse :: (Traversable t, Applicative f) => (a -> f b) -> t a -> f (t b) -- map each elem. of a structure to an action, evaluate from left to right and collect the results
    -- concat :: Foldable t => t [a] -> [a] -- applied type []
    astDeclarationsForLanguage :: Ptr TS.Language -> FilePath -> Q [Dec]
    astDeclarationsForLanguage language filePath = do
      _ <- TS.addDependentFileRelative filePath
      currentFilename <- loc_filename <$> location
      pwd             <- runIO getCurrentDirectory
      let invocationRelativePath = takeDirectory (pwd </> currentFilename) </> filePath
      input <- runIO (eitherDecodeFileStrict' invocationRelativePath) >>= either fail pure
      allSymbols <- runIO (getAllSymbols language)
      debugSymbolNames <- [d|
        debugSymbolNames :: [String]
        debugSymbolNames = $(listE (map (litE . stringL . debugPrefix) allSymbols))
        |]
      (debugSymbolNames <>) . concat @[] <$> traverse (syntaxDatatype language allSymbols) input
    ```

  * `[d|...|] :: Q [Dec]` Oxford bracket: list of top-level declarations

  * `$(...)`: splice

    * [template-haskell-doc](https://downloads.haskell.org/~ghc/7.8.4/docs/html/users_guide/template-haskell.html)

  * `@[] :: * -> *`: List type, enabled by `TypeApplications`

    * [TypeApplications](https://downloads.haskell.org/~ghc/latest/docs/html/users_guide/glasgow_exts.html#extension-TypeApplications)
    * `show (read @Int "5")`

* `getAllSymbols`: build list of all symbols

  * use `TS.ts_language_symbol_count :: Ptr Language -> IO GHC.Word.Word32` to get symbol counts
  * use `TS.ts_language_symbol_name :: Ptr Language -> TSSymbol -> IO CString` to get symbol names
  * `TSSymbol`: defined in TreeSitter
  * `peekCString :: CString -> IO String`: marshal a `\0` terminated C string to Haskell `String`
  * use `TS.ts_language_symbol_type :: Ptr Language -> TSSymbol -> IO Int` to get type (`0 ==> Named`, `1 ==> Anonymous`)

* `syntaxDatatype`: Auto-generate Haskell datatypes for sums, products and leaf types

  * ```haskell
    -- newName :: String -> Q Name -- generate fresh name by TH
    -- 
    syntaxDatatype :: Ptr TS.Language -> [(String, Named)] -> Datatype -> Q [Dec]
    syntaxDatatype language allSymbols datatype = skipDefined $ do
      typeParameterName <- newName "a"
      case datatype of
        SumType (DatatypeName _) _ subtypes -> do
          -- (((((a :+: b) :+: c) :+: d)) :+: e)   ((a :+: b) :+: (c :+: d))
          types' <- fieldTypesToNestedSum subtypes
          let fieldName = mkName ("get" <> nameStr)
          -- no unpack, no strict (!)
          -- name { (t1 :+: t2) a }
          con <- recC name [TH.varBangType fieldName (TH.bangType strictness (pure types' `appT` varT typeParameterName))]
          hasFieldInstance <- makeHasFieldInstance (conT name) (varT typeParameterName) (varE fieldName)
          traversalInstances <- makeTraversalInstances (conT name)
          pure
            (  NewtypeD [] name [PlainTV typeParameterName] Nothing con [deriveGN, deriveStockClause, deriveAnyClassClause]
            :  hasFieldInstance
            <> traversalInstances)
        ProductType (DatatypeName datatypeName) named children fields -> do
          con <- ctorForProductType datatypeName typeParameterName children fields
          symbolMatchingInstance <- symbolMatchingInstance allSymbols name named datatypeName
          traversalInstances <- makeTraversalInstances (conT name)
          pure
            (  generatedDatatype name [con] typeParameterName
            :  symbolMatchingInstance
            <> traversalInstances)
          -- Anonymous leaf types are defined as synonyms for the `Token` datatype
        LeafType (DatatypeName datatypeName) Anonymous -> do
          tsSymbol <- runIO $ withCStringLen datatypeName (\(s, len) -> TS.ts_language_symbol_for_name language s len False)
          -- type name = AST.Token (datatypeName :: GHC.TypeLits.Symbol) (tsSymbol :: GHC.TypeLits.Nat)
          pure [ TySynD name [] (ConT ''Token `AppT` LitT (StrTyLit datatypeName) `AppT` LitT (NumTyLit (fromIntegral tsSymbol))) ]
        LeafType (DatatypeName datatypeName) Named -> do
          con <- ctorForLeafType (DatatypeName datatypeName) typeParameterName
          symbolMatchingInstance <- symbolMatchingInstance allSymbols name Named datatypeName
          traversalInstances <- makeTraversalInstances (conT name)
          -- data ... | instance TS.SymbolMatching | instance Foldable/Functor/Traversable
          pure
            (  generatedDatatype name [con] typeParameterName
            :  symbolMatchingInstance
            <> traversalInstances)
      where
        -- Skip generating datatypes that have already been defined (overridden) in the module where the splice is running.
        skipDefined m = do
          isLocal <- lookupTypeName nameStr >>= maybe (pure False) isLocalName
          if isLocal then pure [] else m
        name = mkName nameStr
        nameStr = toNameString (datatypeNameStatus datatype) (getDatatypeName (AST.Deserialize.datatypeName datatype))
        -- standard derivation for standard/GHC-specific type classes (derive(Eq, Ord, Show, Generic, Generic1))
        deriveStockClause = DerivClause (Just StockStrategy) [ ConT ''Eq, ConT ''Ord, ConT ''Show, ConT ''Generic, ConT ''Generic1]
        -- -XDeriveAnyClass, generate an instance with empty implementations for all methods (derive(TS.Unmarshal, Traversable1 someConstraint))
        -- class (Foldable1 t, Traversable t) => Traversable1 (t :: Type -> Type)
        deriveAnyClassClause = DerivClause (Just AnyclassStrategy) [ConT ''TS.Unmarshal, ConT ''Traversable1 `AppT` VarT (mkName "someConstraint")]
        -- -XGeneralizedNewtypeDeriving, use newtype's underlying type (derive(TS.SymbolMatching))
        deriveGN = DerivClause (Just NewtypeStrategy) [ConT ''TS.SymbolMatching]
        -- data name a = [cons] deriving(...)
        generatedDatatype name cons typeParameterName = DataD [] name [PlainTV typeParameterName] Nothing cons [deriveStockClause, deriveAnyClassClause]
    ```

  * `''T :: Name`, names the type construct `T`

  * `ConT, AppT`

    * [data Type](https://hackage.haskell.org/package/template-haskell-2.16.0.0/docs/Language-Haskell-TH.html#t:Type)

  * `DerivStrategy`: `derive(...)`

    * ![image-20200525014739452](D:\OneDrive\Pictures\Typora\image-20200525014739452.png)

    * ![image-20200525014756533](D:\OneDrive\Pictures\Typora\image-20200525014756533.png)

    * [deriving strategies](https://gitlab.haskell.org/ghc/ghc/-/wikis/commentary/compiler/deriving-strategies)

    * > - Deriving stock instances: This is the usual approach that GHC takes. For certain classes that GHC is aware of, such as `Eq`, `Ord`, `Functor`, `Generic`, and others, GHC can use an algorithm to derive an instance of the class for a particular datatype mechanically. For example, a stock derived `Eq` instance for `data Foo = Foo Int` is:
      >
      > ```
      > instance Eq Foo where
      >   Foo a == Foo b = a == b
      > ```
      >
      > > Stock applies to the "standard" derivable typeclasses mentioned in the Haskell Report like `Eq` and `Show`, as well as some GHC-specific classes like `Data` and `Generic`. The stock strategy only requires enabling language extensions in certain cases (`DeriveFunctor`, `DeriveGeneric`, etc.).
      >
      > - `GeneralizedNewtypeDeriving`: An approach that GHC only uses if the eponymous language extension is enabled, and if an instance is being derived for a newtype. GHC will reuse the instance of the newtype's underlying type to generate an instance for the newtype itself. For more information, see http://downloads.haskell.org/~ghc/8.0.1/docs/html/users_guide/glasgow_exts.html#generalised-derived-instances-for-newtypes
      > - `DeriveAnyClass`: An approach that GHC only uses if the eponymous language extension is enabled. When this strategy is invoked, GHC will simply generate an instance with empty implementations for all methods. For more information, see http://downloads.haskell.org/~ghc/8.0.1/docs/html/users_guide/glasgow_exts.html#deriving-any-other-class

  * `Traversable1`

    * [explanation](https://github.com/fantasyland/fantasy-land/issues/305)
    * [glassery](http://oleg.fi/gists/posts/2017-04-18-glassery.html)
    * ![image-20200525021355726](D:\OneDrive\Pictures\Typora\image-20200525021355726.png)

  * `Apply`: A strong lax semi-monoidal endofunctor. This is equivalent to an `Applicative` without `pure`.

    * [hackage](https://hackage.haskell.org/package/semigroupoids-5.3.4/docs/Data-Functor-Apply.html#g:2)
    * ![image-20200525021612494](D:\OneDrive\Pictures\Typora\image-20200525021612494.png)

  * ![image-20200525022836070](D:\OneDrive\Pictures\Typora\image-20200525022836070.png)

    * [TH-syntax](https://hackage.haskell.org/package/template-haskell-2.16.0.0/docs/Language-Haskell-TH.html#t:Dec)

  * `SumType (DataTypeName _) _ subtypes` template

    * ```haskell
      -- name = getDatatypeName . datatypeName datatype (PascalCase)
      newtype name a = name {
      		(t1 :+: t2) a
      	}
      	deriving stock (Eq, Ord, Show, Generic, Generic1)
      	deriving(TS.SymbolMatching, TS.Unmarshal, Traversable1 someConstraint)
      
      -- class HasField x r a | x r -> a
      -- Constraint representing the fact that the field x belongs to the record type r and has field type a. This will be solved automatically, but manual instances may be provided as well.
      instance HasField "ann" (name a) a where
      	getField = TS.gann . getName
      	
      instance Foldable name where
          foldMap = foldMapDefault1
      
      instance Functor name where
          fmap = fmapDefault1
      
      instance Traversable name where
          traverse = traverseDefault1
      ```

  * `ProductType (DataTypeName datatypeName) named children fields` template

    * ```haskell
      data name a = name {
      	ann :: a,
      	t1 :: NonEmpty ((t2 :+: t3) a),	-- required, multiple
      	t2 :: (t3 :+: t4),	-- required, single
      	t3 :: [t5], 	-- optional, multiple
      	t4 :: Maybe t6, -- optional, single
      	extra_chidren :: T -- children
      }
      deriving stock (Eq, Ord, Show, Generic, Generic1)
      deriving(TS.Unmarshal, Traversable1 someConstraint)
      	
      instance TS.SymbolMatching name where
      	matchedSymbols :: SymbolMatching a => Proxy a -> [Int]
      	matchedSymbols _ = [1, 2, 3]
      	showFailure :: SymbolMatching a => Proxy a -> Node -> String
      	showFailure _ node = "expected " <> name <> " but got ERROR/symbolName [(r1, c1)] - [(r2, c2)]"
      instance Traversal ..
      ```

  * `LeafType (DataTypeName datatypeName) Named` template

    * ```haskell
      data name a = name {
      	ann :: a,
      	text :: Text
      }
      deriving stock (Eq, Ord, Show, Generic, Generic1)
      deriving(TS.Unmarshal, Traversable1 someConstraint)
      
      instance TS.SymbolMatching ..
      instance Traversal ..
      ```

  * `LeafType (DataTypeName datatypeName) Anonymous` template

    * ```haskell
      -- name = Anonymous <> getDatatypeName . datatypeName datatype
      type name = AST.Token 
      	(datatypeName :: GHC.TypeLits.Symbol) 
      	(tsSymbol :: GHC.TypeLits.Nat)
      ```

* [GHC-Generic](https://hackage.haskell.org/package/base-4.14.0.0/docs/GHC-Generics.html#t:Generic)
* Now the language AST is represented as `GHC.Generic` by auto deriving and template generating (`(:+:)`)
* also provide the traverse functions



### Deserialize

* `Datatype = SumType | ProductType | LeafType`

  * ```haskell
    data Datatype
      = SumType
      { datatypeName       :: DatatypeName
      , datatypeNameStatus :: Named
      , datatypeSubtypes   :: NonEmpty Type
      }
      | ProductType
      { datatypeName       :: DatatypeName
      , datatypeNameStatus :: Named
      , datatypeChildren   :: Maybe Children
      , datatypeFields     :: [(String, Field)]
      }
      | LeafType
      { datatypeName       :: DatatypeName
      , datatypeNameStatus :: Named
      }
      deriving (Eq, Ord, Show, Generic, ToJSON)
    ```

  * with `FromJSON` instance

    * ```haskell
      -- lazy parsing for SumType?
      -- example node-types.json: https://github.com/tree-sitter/tree-sitter-python/blob/118cf40115e13e95ed3ac4c0e05c0534e07bc0fa/src/node-types.json
      instance FromJSON Datatype where
        -- withObject :: String -> (Object -> Parser a) -> Value -> Parser a
        parseJSON = withObject "Datatype" $ \v -> do
          -- (.:) :: FromJSON a => Object -> Text -> Parser a
          -- retreive the value assoicated with the given key of an object
          type' <- v .: "type"
          named <- v .: "named"
          -- (.:?) :: FromJSON a => Object -> Text -> Parser (Maybe a)
          -- subtypes :: NonEmpty Type (type has FromJSON instance)
          subtypes <- v .:? "subtypes"
          case subtypes of
            Nothing -> do
              fields <- fmap (fromMaybe HM.empty) (v .:? "fields")
              children <- v .:? "children"
              -- null :: Foldable t => t a -> Bool
              if null fields && null children then
                pure (LeafType type' named)
              else
                ProductType type' named children <$> parseKVPairs (HM.toList fields)
            Just subtypes   -> pure (SumType type' named subtypes)
      ```

  * `Field`

    * ```haskell
      data Field = MkField
        { fieldRequired :: Required
        , fieldTypes    :: NonEmpty Type
        , fieldMultiple :: Multiple
        }
        deriving (Eq, Ord, Show, Generic, ToJSON)
      
      instance FromJSON Field where
        parseJSON = genericParseJSON customOptions
      ```

  * `newtype Children = MkChildren Field`

    * ```haskell
      newtype Children = MkChildren Field
        deriving (Eq, Ord, Show, Generic)
        deriving newtype (ToJSON, FromJSON)
      ```

  * some options

    * ```haskell
      data Required = Optional | Required
        deriving (Eq, Ord, Show, Generic, ToJSON)
      
      instance FromJSON Required where
        parseJSON = withBool "Required" (\p -> pure (if p then Required else Optional))
      
      data Named = Anonymous | Named
        deriving (Eq, Ord, Show, Generic, ToJSON, Lift)
      
      instance FromJSON Named where
        parseJSON = withBool "Named" (\p -> pure (if p then Named else Anonymous))
      
      data Multiple = Single | Multiple
        deriving (Eq, Ord, Show, Generic, ToJSON)
      
      instance FromJSON Multiple where
        parseJSON = withBool "Multiple" (\p -> pure (if p then Multiple else Single))
      ```

  * `Type`

    * ```haskell
      data Type = MkType
        { fieldType :: DatatypeName
        , isNamed :: Named
        }
        deriving (Eq, Ord, Show, Generic, ToJSON)
      
      instance FromJSON Type where
        parseJSON = genericParseJSON customOptions
        
      customOptions :: Aeson.Options
      customOptions = Aeson.defaultOptions
        {
        	-- Function applied to field labels. toLower first . dropWhile isLower
          fieldLabelModifier = initLower . dropPrefix
          -- Function applied to constructor tags which could be handy for lower-casing them for example.
        , constructorTagModifier = initLower
        }
      ```

* combining `nodes-type.json`, `GenerateSyntax`, `Deserialize`, we get the template generated Haskell data types for language symbols.



### Unmarshal

* [fuse-effects](https://www.youtube.com/watch?v=vfDazZfxlNs)
* [Abstracting Definitional Interpreters](https://arxiv.org/pdf/1707.04755.pdf)

* `parseByteString`: parse source code and produce AST

  * ```haskell
    -- withParser :: Ptr Language -> (Ptr Parser -> IO a) -> IO a (where a = Either [Char] (t a))
    -- withParserTree :: Ptr Parser -> ByteString -> (Ptr Tree -> IO a) -> IO a
    parseByteString :: (Unmarshal t, UnmarshalAnn a) => Ptr TS.Language -> ByteString -> IO (Either String (t a))
    parseByteString language bytestring = withParser language $ \ parser -> withParseTree parser bytestring $ \ treePtr ->
      if treePtr == nullPtr then
        pure (Left "error: didn't get a root node")
      else
    	-- withRootNode :: Ptr Tree -> (Ptr Node -> IO a) -> IO a
        withRootNode treePtr $ \ rootPtr ->
    	  -- withCursor :: Ptr TSNode -> (Ptr Cursor -> IO a) -> IO a
    	  -- liftIO :: MonadIO m => IO a -> m a (lift a computation from the `IO` monad)
    	  -- unmarshalNode :: Node -> MatchM (t a) (type MatchM = ReaderC UnmarshalState IO)
    	  -- UnmarshalState { source :: !ByteString, cursor :: !(Ptr Cursor) }
          withCursor (castPtr rootPtr) $ \ cursor ->
            (Right <$> runReader (UnmarshalState bytestring cursor) (liftIO (peek rootPtr) >>= unmarshalNode))
              `catch` (pure . Left . getUnmarshalError)
    ```

  * use example

    * ```haskell
      -- with TypeApplications
      TS.parseByteString 
      	@Language.Rust.AST.SourceFile 
      	@(Source.Span.Span, Source.Range.Range) 
      	Language.Rust.Grammar.tree_sitter_rust "let x = 1;"
      ```

    * 









## Core



## Language-specific

* use `AST.Grammar.TH` to convert `TreeSitter` 

  * ```haskell
    {-# LANGUAGE TemplateHaskell #-}
    module Language.TSX.Grammar
    ( tree_sitter_tsx
    , Grammar(..)
    ) where
    
    import AST.Grammar.TH
    import Language.Haskell.TH
    import TreeSitter.TSX (tree_sitter_tsx)
    
    -- | Statically-known rules corresponding to symbols in the grammar.
    mkStaticallyKnownRuleGrammarData  (mkName "Grammar") tree_sitter_{...}
    ```

  * `(..)` grammar

    * > - The form `T(..)`, where `T` is a data family, names the family `T` and all the in-scope constructors (whether in scope qualified or unqualified) that are data instances of `T`.
      > - The form `C(..)`, where `C` is a class, names the class `C` and all its methods *and associated types*.

    * [import-and-export-pattern-synoyms](https://downloads.haskell.org/~ghc/latest/docs/html/users_guide/glasgow_exts.html#import-and-export-of-pattern-synonyms)

    * [import-and-export](https://downloads.haskell.org/~ghc/latest/docs/html/users_guide/glasgow_exts.html#import-and-export)

  * generated template

    * ```haskell
      -- defined in AST.Grammar.TH
      -- duplicated names are modified to Name', Name''
      data Grammar = S1 | S2 | ..
      deriving stock (Bounded, Enum, Eq, Ix, Ord, Show)
      instance Symbol Grammar where
      	symbolType = \case {
      		S1 -> ST1;
      		S2 -> ST2;
      		..;
      	}
      ```

    * 

* use `AST.GenerateSyntax.astDeclarationsForLanguage` to convert `tree_sitter_xxx`

  * ```haskell
    {-# LANGUAGE DataKinds #-}
    {-# LANGUAGE DeriveAnyClass #-}
    {-# LANGUAGE DeriveGeneric #-}
    {-# LANGUAGE DeriveTraversable #-}
    {-# LANGUAGE DerivingStrategies #-}
    {-# LANGUAGE DuplicateRecordFields #-}
    {-# LANGUAGE FlexibleInstances #-}
    {-# LANGUAGE GeneralizedNewtypeDeriving #-}
    {-# LANGUAGE MultiParamTypeClasses #-}
    {-# LANGUAGE TemplateHaskell #-}
    {-# LANGUAGE TypeApplications #-}
    
    module Language.Python.AST
    ( module Language.Python.AST
    , Python.getTestCorpusDir
    ) where
    
    import           Prelude hiding (False, Float, Integer, String, True)
    import           AST.GenerateSyntax
    import           Language.Haskell.TH.Syntax (runIO)
    import qualified TreeSitter.Python as Python (getNodeTypesPath, getTestCorpusDir, tree_sitter_python)
    
    -- runIO :: IO a -> Q a
    -- getTestCorpusDir :: IO FilePath
    -- getTestCorpusDir = getDataFileName "vendor/tree-sitter-python/test/corpus"
    -- getNodeTypesPath :: IO FilePath
    -- getNodeTypesPath = getDataFileName "vendor/tree-sitter-python/src/node-types.json"
    -- tree_sitter_python :: Ptr Language
    -- foreign import ccall unsafe "vendor/tree-sitter-python/src/parser.c tree_sitter_python" tree_sitter_python :: Ptr Language
    -- astDeclarationsForLanguage :: Ptr Language -> FilePath -> Q [Dec]
    runIO Python.getNodeTypesPath >>= astDeclarationsForLanguage Python.tree_sitter_python
    ```

  * the tree-sitter exports is defined in [vendor](https://github.com/tree-sitter/haskell-tree-sitter/tree/master/tree-sitter-python)

    * the grammar is defined in Javascript, where `$` refers to the module, then it generates `binding.cc`, `parser.cc` for incrementing parsing. Also use `corpus.txt` (plain code & S-expressions) for testing

    * syntax is like

      * ```javascript
        _declaration_statement: $ => choice(
            $.const_item,
            $.macro_invocation,
            $.macro_definition,
            $.empty_statement,
            $.attribute_item,
            $.inner_attribute_item,
            $.mod_item,
            $.foreign_mod_item,
            $.struct_item,
            $.union_item,
            $.enum_item,
            $.type_item,
            $.function_item,
            $.function_signature_item,
            $.impl_item,
            $.trait_item,
            $.associated_type,
            $.let_declaration,
            $.use_declaration,
            $.extern_crate_declaration,
            $.static_item
        ),
            
        macro_definition: $ => {
            const rules = seq(
                repeat(seq($.macro_rule, ';')),
                optional($.macro_rule)
            )
        
            return seq(
                'macro_rules!',
                field('name', $.identifier),
                choice(
                    seq('(', rules, ')', ';'),
                    seq('{', rules, '}')
                )
            )
        },
        ```

  * `module Y( module Y )`: exports all entities defined in `Y`

    * [module-export-examples](https://downloads.haskell.org/~ghc/latest/docs/html/users_guide/glasgow_exts.html#examples)

  * `Q`: the monad that warps the computations that can be run in the GHC compiler at compile time

    * [CIS194-template-haskell](https://www.cis.upenn.edu/~cis194/fall14/lectures/11-template-haskell.html)
    * 

