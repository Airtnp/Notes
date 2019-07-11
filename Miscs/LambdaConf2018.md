# LambdaConf 2018



## Free All The Things

* [adjunction-battleship](https://chrispenner.ca/posts/adjunction-battleship)

* [free-forgetful-functors](https://chrispenner.ca/posts/free-forgetful-functors)

* [free-algebra](https://thzt.github.io/2017/07/04/free-algebra/)

* [free-monad-and-free-applicative](https://zhuanlan.zhihu.com/p/21291746)

* A free functor is left adjoint to a forgetful functor

* ![1561703088839](D:\OneDrive\Pictures\Typora\1561703088839.png)

* Interpreter by free laws

  * define AST (ADT)
  * add `Inject` (ADT -> Free Monad)
  * write interpreter (Natural transformation, `F[A] -> FreeMonad`)
  * check laws

* Advantages

  * nice API using typeclass
  * use `Free X` as `X`
  * program reified into data structure
  * structure can be analyzed/optimized
  * one program - many interpretations
  * deep embeddings / initial encoding / data structure representation
  * not finally tagless

* Free Monad

* ```scala
  trait Monad[F[_]] {
      def pure[A](x: A): F[A]
      def flatMap[A, B](fa: F[A])(f: A => F[B]): F[B]
  }
  // left identity
  pure(a).flatMap(f) === f(a)
  // right identity
  fa.flatMap(pure) === fa
  // associativity
  fa.flatMap(f).flatMap(g) === fa.flatMap(a => f(a).flatMap(g))
  ```

* ```scala
  sealed abstract class Free[F[_], A]
  final case class Pure[F[_], A](a: A) extends Free[F, A]
  final case class FlatMap[F[_], A, B](
  	fa: Free[F, A],
      f: A => Free[F, B])
  	extends Free[F, B]
  final case class Inject[F[_], A](fa: F[A]) extends Free[F, A]
  
  implicit def freeMonad[F[_], A]: Monad[Free[F, ?]] = 
  	new Monad[Free[F, ?]] {
          def pure[A](x: A): Free[F, A] = Pure(x)
          // not obey Monad rules
          // def flatMap[A, B](fa: Free[F, A])(
          // 	f: A => Free[F, B]): Free[F, B] = 
          // FlatMap(fa, f)
          def flatMap[A, B](fa: Free[F, A])(
          	f: A => Free[F, B]): Free[F, B] = fa match {
              case Pure(x) => f(x) // left identity
              case Inject(fa) => FlatMap(Inject(fa), f)
              case FlatMap(ga, g) => // associativity
              	FlatMap(ga, (a: Any)) => FlatMap(g(a), f)
          }
      }
  
  def runFree[F[_], M[_]: Monad, A](nat: F ~> M)(
  	free: Free[F, A]): M[A] = free match {
  	case Pure(x) 		=> Monad[M].pure(x)
      case Inject(fa) 	=> nat(fa)
      case FlatMap(fa, f) => Monad[M].flatMap(
      	runFree(nat)(fa)
      )(x => runFree(nat)(f(x)))
  }
  ```

  * DSL with monadic expressiveness
  * context sensitive, branching, loops, fancy control flow
  * familiarity with monadic style for DSL
  * big drawback: interpreter has limited possibilities
  * [free-monads-are-simple](https://underscore.io/blog/posts/2015/04/14/free-monads-are-simple.html)

* Free Applicative

  * ```scala
    trait Applicative[F[_]] {
        def pure[A](x: A): F[A]
        def ap[A, B](fab: F[A => B], fa: F[A]): F[B]
    }
    // identity
    Ap(Pure(identity), v) === v
    // composition
    Ap(Ap(Ap(Pure(_.compose), u), v), w) === Ap(u, Ap(v, w))
    // homomorphism
    Ap(Pure(f), Pure(x)) === Pure(f(x))
    // intercharge
    Ap(u, Pure(y)) === Ap(Pure(_(y)), u)
    ```

  * ```scala
    sealed abstract class FreeAp[F[_], A]
    final case class Pure[F[_], A](a: A) extends FreeAp[F, A]
    final case class Ap[F[_], A, B](
    	fab: FreeAp[F, A => B],
    	fa: FreeAp[F, A])
    	extends FreeAp[F, B]
    final case class Inject[F[_], A](fa: F[A]) extends FreeAp[F, A]
    
    def ap[A, B](fa: FreeAp[F, A => B], fa: FreeAp[F, A]): FreeAp[F, B] =
    	(fab, fa) match {
            case (Pure(f), Pure(x)) => Pure(f(x)) // homomorphism
            case (u, Pure(y)) => Ap(Pure((f: A => B) => f(y)), u) // interchange
            case (_, _) => Ap(fab, fa)
        }
    
    def runFreeAp[F[_], M[_]: Applicative, A](
    	nat: F ~> M)(free: FreeAp[F, A]): M[A] =
    	free match {
    		case Pure(x) => Applicative[M].pure(x)
    		case Inject(fa) => nat(fa)
    		case Ap(fab, fa) =>
    			Applicative[M]
    			.ap(runFreeAp(nat)(fab), runFreeAp(nat)(fa))
    	}
    
    ```

  * DSL with applicative expressiveness

  * context insensitive

  * pure computation over effectful arguments

  * more freedom during interpretation

* Free Functor

  * ```scala
    trait Functor[F[_]] {
        def map[A, B](fa: F[A])(f: A => B): F[B]
    }
    sealed abstract class FreeFunctor[F[_], A]
    case class Fmap[F[_], X, A](fa: F[X])(f: X => A)
    def inject[F[_], A](value: F[A]) = Fmap(value)(identity)
    ```

  * 

    ```scal
    sealed abstract class Coyoneda[F[_], A] {
    	type X
    	def fa: F[X]
    	def f: X => A
    }
    def inject[F[_], A](v: F[A]) = new Coyoneda[F, A] {
    	type X = A
    	def fa = v
    	def f = identity
    }
    
    implicit def coyoFun[F[_]]: Functor[Coyoneda[F, ?]] = 
    	new Functor[Coyoneda[F, ?]] {
    		def map[A, B](coyo: Coyoneda[F, A])(
    			g: A => B): Coyoneda[F, B] = 
    			new Coyoneda[F, B] {
    				type X = coyo.X
    				def fa = coyo.fa
    				def f = g.compose(coyo.f)
    			}
    	}
    	
    def runCoyo[F[_]: Functor, A](
    	coyo: Coyoneda[F, A]): F[A] = 
    	Functor[F].map(coyo.fa)(coyo.f)
    ```

  * map fusion

* Free Monoid

  * ```scala
    trait Monoid[A] {
    	def empty: A
    	def combine(x: A, y: A): A
    }
    // left identity
    empty |+| x === x
    // right identity
    x |+| empty === x
    // associativity
    1 |+| (2 |+| 3) === (1 |+| 2) |+| 3
    ```

  * 

    ```scala
    sealed trait NotCombine[+A]
    sealed abstract class FreeMonoid[+A]
    case object Empty extends FreeMonoid[Nothing]
    	with NotCombine[Nothing]
    case class Inject[A](x: A) extends FreeMonoid[A]
    	with NotCombine[A]
    case class Combine[A](x: NotCombine[A],
    					  y: FreeMonoid[A])
    	extends FreeMonoid[A]
    
    implicit def monoid[A]: Monoid[FreeMonoid[A]] =
    	new Monoid[FreeMonoid[A]] {
    		override def empty = Empty
    		override def combine(
    			x: FreeMonoid[A],
    			y: FreeMonoid[A]): FreeMonoid[A] = x match {
    			case Empty => y
    			case Combine(h, t) => Combine(h, combine(t, y))
    	}
    }
    ```

* Free Boolean Algebra



## Type theory behind GHC internals

* libraries

  * ![1561812352365](D:\OneDrive\Pictures\Typora\1561812352365.png)

* rts

  * ![1561812336470](D:\OneDrive\Pictures\Typora\1561812336470.png)

* ![1561812370138](D:\OneDrive\Pictures\Typora\1561812370138.png)

* compiler

  * ![1561812387756](D:\OneDrive\Pictures\Typora\1561812387756.png)

  * ![1561812401881](D:\OneDrive\Pictures\Typora\1561812401881.png)

  * AST

    * ![1561812424442](D:\OneDrive\Pictures\Typora\1561812424442.png)
    * 

    ```haskell
    data HsModule name
        = HsModule {
            hsmodName :: Maybe
    			        (Located ModuleName),
            hsmodExports :: Maybe
            			(Located [LIE name]),
            hsmodImports :: [LImportDecl name],
            hsmodDecls :: [LHsDecl name],
            -- ...
        }
    
    type LHsDecl id = Located (HsDecl id)
    data HsDecl id
        = TyClD (TyClDecl id)
        | InstD (InstDecl id)
        | DerivD (DerivDecl id)
        | ValD (HsBind id)
        | SigD (Sig id)
        | DefD (DefaultDecl id)
        | ForD (ForeignDecl id)
        | WarningD (WarnDecls id)
        | AnnD (AnnDecl id)
        | RuleD (RuleDecls id)
        | VectD (VectDecl id)
        | SpliceD (SpliceDecl id)
        | DocD (DocDecl)
        | RoleAnnotD (RoleAnnotDecl id)
    ```

  * type-checking

    * ![1561812592893](D:\OneDrive\Pictures\Typora\1561812592893.png)

  * Core and optimisation

    * ![1561812613576](D:\OneDrive\Pictures\Typora\1561812613576.png)

    * ```haskell
      type CoreBndr = Var
      type CoreExpr = Expr CoreBndr
      data Expr b
          = Var Id
          | Lit Literal
          | App (Expr b) (Arg b)
          | Lam b (Expr b)
          | Let (Bind b) (Expr b)
          | Case (Expr b) b Type [Alt b]
          | Cast (Expr b) Coercion
          | Tick (Tickish Id) (Expr b)
          | Type Type
          | Coercion Coercion
      
      type Arg b = Expr b
      type Alt b = (AltCon, [b], Expr b)
      data AltCon = DataAlt DataCon
                  | LitAlt Literal
                  | DEFAULT
      data Bind b = NonRec b (Expr b)
      			| Rec [(b, (Expr b))]
      ```

    * ![1561812692032](D:\OneDrive\Pictures\Typora\1561812692032.png)

    * ![1561812707840](D:\OneDrive\Pictures\Typora\1561812707840.png)

    * simplifier + term rewrite rules + strictness analysis + overloading specialisation

  * prepare to code generation

    * ![1561812955214](D:\OneDrive\Pictures\Typora\1561812955214.png)

  * code generation

    * ![1561812976639](D:\OneDrive\Pictures\Typora\1561812976639.png)
    * bytecode/native code/C-code/LLVM IR

* Extend compiler

  * user-defined rewriting rules
    * ![1561813044339](D:\OneDrive\Pictures\Typora\1561813044339.png)
  * compiler plugins
    * single optimisation step iteration
    * function of `Core -> Core`
  * GHC as a library (GHC API)
    * steps modularity
    * every step is a function
    * compiler as part of user application

* UTLC

  * ![1561943696992](D:\OneDrive\Pictures\Typora\1561943696992.png)
  * ![1561943708339](D:\OneDrive\Pictures\Typora\1561943708339.png)

* STLC

  * ![1561943731209](D:\OneDrive\Pictures\Typora\1561943731209.png)
  * ![1561943746259](D:\OneDrive\Pictures\Typora\1561943746259.png)
  * ![1561943754029](D:\OneDrive\Pictures\Typora\1561943754029.png)

* safety = progress + preservation

  * progress: correctly typed term is either value or can be further evaluated
  * preservation: if correctly typed term is evaluated then resulting term is correctly typed

* System F

  * ![1561943846070](D:\OneDrive\Pictures\Typora\1561943846070.png)
  * ![1561943862096](D:\OneDrive\Pictures\Typora\1561943862096.png)
  * ![1561943878798](D:\OneDrive\Pictures\Typora\1561943878798.png)
  * ![1561943886362](D:\OneDrive\Pictures\Typora\1561943886362.png)
  * ![1561943893869](D:\OneDrive\Pictures\Typora\1561943893869.png)
  * ![1561943899879](D:\OneDrive\Pictures\Typora\1561943899879.png)
  * `fix` for non-normalized functions
  * type erasure
  * type reconstruction is undecidable
  * limited: prenex polymorphism (rank 2)
  * impredicativity

* System F omega

  * ![1561944018277](D:\OneDrive\Pictures\Typora\1561944018277.png)
  * ![1561944033011](D:\OneDrive\Pictures\Typora\1561944033011.png)
  * ![1561944040876](D:\OneDrive\Pictures\Typora\1561944040876.png)

* GHC type system

  * before 2006, System F omega + ADT (existentials)
  * System FC (equality constraints & coercions)
  * ![1561944151647](D:\OneDrive\Pictures\Typora\1561944151647.png)
  * GADT + System FC
    * ![1561944307927](D:\OneDrive\Pictures\Typora\1561944307927.png)
    * ![1561944318653](D:\OneDrive\Pictures\Typora\1561944318653.png)
    * ![1561944326167](D:\OneDrive\Pictures\Typora\1561944326167.png)
    * ![1561944340435](D:\OneDrive\Pictures\Typora\1561944340435.png)
  * System FC2
    * type as encoding/representation
    * nominal equality / representation equality
    * ![1561944448683](D:\OneDrive\Pictures\Typora\1561944448683.png)
  * System FC↑
    * ![1561944636773](D:\OneDrive\Pictures\Typora\1561944636773.png)
    * ![1561944657621](D:\OneDrive\Pictures\Typora\1561944657621.png)
    * ![1561944666505](D:\OneDrive\Pictures\Typora\1561944666505.png)
    * ![1561944671782](D:\OneDrive\Pictures\Typora\1561944671782.png)
    * explicit kind equality
      * ![1561944699670](D:\OneDrive\Pictures\Typora\1561944699670.png)

* GHC 2015

  * ![1561944717036](D:\OneDrive\Pictures\Typora\1561944717036.png)
  * ![1561944724744](D:\OneDrive\Pictures\Typora\1561944724744.png)

* System D (dependent type)

  * ![1561944834818](D:\OneDrive\Pictures\Typora\1561944834818.png)
  * ![1561944842516](D:\OneDrive\Pictures\Typora\1561944842516.png)
  * ![1561944867100](D:\OneDrive\Pictures\Typora\1561944867100.png)



## Extensibly Free Arrows

* ![1562376069287](D:\OneDrive\Pictures\Typora\1562376069287.png)

* ![1562376097114](D:\OneDrive\Pictures\Typora\1562376097114.png)

* ![1562378231981](D:\OneDrive\Pictures\Typora\1562378231981.png)

* ![1562378239267](D:\OneDrive\Pictures\Typora\1562378239267.png)

* ![1562378258662](D:\OneDrive\Pictures\Typora\1562378258662.png)

* ![1562378263860](D:\OneDrive\Pictures\Typora\1562378263860.png)

* ![1562378294477](D:\OneDrive\Pictures\Typora\1562378294477.png)

* ![1562378303930](D:\OneDrive\Pictures\Typora\1562378303930.png)

* ![1562378312301](D:\OneDrive\Pictures\Typora\1562378312301.png)

* ```haskell
  data FreeA eff a b where
      Pure :: (a -> b) -> FreeA eff a b
      Effect :: eff a b -> FreeA eff a b
      Seq :: FreeA eff a b -> FreeA eff b c -> FreeA eff a c
      Par :: FreeA eff a1 b1 -> FreeA eff a2 b2 -> FreeA eff (a1, a2) (b1, b2)
      -- Apply -- | Arrow apply
      -- FanIn -- | Arrow Choice
      -- Spl -- | Arrow Choice
      
  instance C.Category (FreeA eff) where
      id = Pure id
      (.) = flip Seq
  
  instance Arrow (FreeA eff) where
      arr = Pure
      first f = Par f C.id
      second f = Par C.id f
      (***) = Par
      
  compileA :: forall eff arr a0 b0. (Arrow arr) => (forall a b. eff a b -> arr a b) -> FreeA eff a0 b0 -> arr a0 b0
  compileA exec = go
  	where
          go :: forall a b . (Arrow arr) => FreeA eff a b -> arr a b
          go freeA = case freeA of
          Pure f -> arr f
          Seq f1 f2 -> go f2 C.. go f1
          Par f1 f2 -> go f1 *** go f2
          Effect eff -> exec eff
  
  evalKleisliA :: forall m a b . ( Monad m ) => FreeA (Kleisli m) a b -> Kleisli m a b
  evalKleisliA = go
  	where
          go :: forall m a b . (Monad m) => FreeA (Kleisli m) a b -> Kleisli m a b
          go freeA = case freeA of
              Pure f -> Kleisli $ return . f
              Effect eff -> eff
              Seq f1 f2 -> go f2 C.. go f1
              Par f1 f2 -> go f1 *** go f2
  
  liftK :: Monad m => (b -> m c) -> FreeA (Kleisli m) b c
  liftK eff = Effect (Kleisli $ \x -> eff x)
  
      
  data PrintX a b where
  	Print :: PrintX Text ()
  
  interpPrintX :: (MonadIO m) => PrintX a b -> FreeA (Kleisli m) a b
  interpPrintX Print = liftK (\x -> liftIO $ T.putStrLn x)
  
  interpPrintXToFile :: (MonadIO m) => PrintX a b -> FreeA (Kleisli m) a b
  interpPrintXToFile Print = liftK (\x -> liftIO $ T.writeFile "output.txt" x)
  
  printA :: (eff :>+: PrintX) => FreeA eff Text ()
  printA = lftE Print
  
  storeA :: (eff :>+: StoreX) => FreeA eff String ()
  storeA = lftE Store
  
  extensibleArrow :: (eff :>+: PrintX, eff :>+: StoreX) => FreeA eff Text ()
  extensibleArrow = proc x -> do
      printA -< x
      storeA -< T.unpack x
      Pure id -< ()
      
  runKleisli (evalKleisliA $ compileA (interpPrintX <#>
  interpStoreXToFile) extensibleArrow) ("Extensible Arrow" :: Text)
  ```

* ![1562378618111](D:\OneDrive\Pictures\Typora\1562378618111.png)



## Practical Introduction to Substructural Type System through Linear Haskell and Rust

* guaranteed use of a value
* safe channel communication
* safe handling of a resource
* How to ensure `appendF` not after `closeF`?
* unrestricted use of a variable
  * drop
  * duplicate
  * reorder
* substructural rules
  * exchange
    * type check in any desired order when multiple terms have to be checked at the same time
    * restricting -> in a stack order (FILO order)
  * contraction
    * use a variable twice in a type safe way
    * `dup x = (x, x) :: a -> (a, a)`
    * restricting -> can't use a term more than once
  * weakening
    * discard unnecessary type proofs
    * `kill x = () :: a -> ()`
    * restricting -> must use a term at least once
* substructural type systems remove or replace 1+ substructural rules
  * ![1562380374789](D:\OneDrive\Pictures\Typora\1562380374789.png)
  * Rust: Affine
  * Linear Haskell: Linear
* Linear Haskell
  * ![1562380490336](D:\OneDrive\Pictures\Typora\1562380490336.png)
  * Can't define `fst (a, b) = a :: (a, b) ⊸ a` (linear weight of `b` not match 1)
  * Linear IO Monad
  * `Unrestricted`
* Rust
  * ![1562380810675](D:\OneDrive\Pictures\Typora\1562380810675.png)
  * ![1562381324763](D:\OneDrive\Pictures\Typora\1562381324763.png)
  * ![1562381356922](D:\OneDrive\Pictures\Typora\1562381356922.png)
  * ![1562381508364](D:\OneDrive\Pictures\Typora\1562381508364.png)
  * ![1562381524192](D:\OneDrive\Pictures\Typora\1562381524192.png)
  * ![1562381530989](D:\OneDrive\Pictures\Typora\1562381530989.png)
* ![1562381552776](D:\OneDrive\Pictures\Typora\1562381552776.png)
* ![1562381568595](D:\OneDrive\Pictures\Typora\1562381568595.png)



## Crash Course on Notation in PLT

* ![1562381719874](D:\OneDrive\Pictures\Typora\1562381719874.png)
* ![1562381724879](D:\OneDrive\Pictures\Typora\1562381724879.png)
* ![1562381730239](D:\OneDrive\Pictures\Typora\1562381730239.png)
* ![1562381736358](D:\OneDrive\Pictures\Typora\1562381736358.png)
* ![1562381756816](D:\OneDrive\Pictures\Typora\1562381756816.png)
* ![1562381782047](D:\OneDrive\Pictures\Typora\1562381782047.png)
* ![1562381806229](D:\OneDrive\Pictures\Typora\1562381806229.png)
* ![1562381813180](D:\OneDrive\Pictures\Typora\1562381813180.png)
* ![1562381833600](D:\OneDrive\Pictures\Typora\1562381833600.png)
* ![1562381845542](D:\OneDrive\Pictures\Typora\1562381845542.png)
* ![1562381852906](D:\OneDrive\Pictures\Typora\1562381852906.png)
* ![1562381872282](D:\OneDrive\Pictures\Typora\1562381872282.png)
* ![1562381878414](D:\OneDrive\Pictures\Typora\1562381878414.png)



