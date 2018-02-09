-- ref: https://www.cis.upenn.edu/~bcpierce/tapl/checkers/fullfsub/syntax.ml
-- TODO: the error handling is shit. Try replace everything by Either Type/Term Error
-- TODO: add Kind system
-- Fullformsub is the ultra in TAPL: https://www.cis.upenn.edu/~bcpierce/tapl/checkers/fullfomsub/
import Data.Maybe
import Data.List
import Control.Exception
import System.IO.Unsafe

data Kind = 
    KnStar
    | KnArr Kind Kind

data Type = 
    TyVar Int Int
    | TyId String
    | TyTop
    | TyBot
    | TyArr Type Type
    | TyRecord [(String, Type)]
    | TyVariant [(String, Type)]
    | TyRef Type                    -- invariant subtyping
    | TyString
    | TyUnit
    | TyFloat
    | TyNat    
    | TyBool    
    | TyAll String Type Type        -- forall X <: T. (better TyAll String Kind Type)
    | TySome String Type Type       -- exist X <: T. (better TySome String Kind Type)
    | TySource Type                 -- covariant subtyping
    | TySink Type
    deriving(Eq, Show)
    -- TyAbs String Kind Type
    -- TyApp Type Type              -- Type operations

data Term = 
    TmVar Int Int                   -- Γ⊢a
    | TmAbs String Type Term        -- Γ⊢x:T.t1 (T->)
    | TmApp Term Term               -- Γ⊢M N
    | TmTrue
    | TmFalse
    | TmString String
    | TmUnit
    | TmFloat Float    
    | TmIf Term Term Term
    | TmRecord [(String, Term)]
    | TmProj Term String            -- record <-> proj
    | TmCase Term [(String, (String, Term))]
    | TmTag String Term Type
    | TmLet String Term Term        -- let x = t1 in t2 === (\x:T1 t2) t1 === [x -> t1]t2
    | TmFix Term                    -- fix \x:T1 t2 === [x -> fix \x:T1 t2]t2
    | TmAscribe Term Type           -- as
    | TmTimesFloat Term Term
    | TmTAbs String Type Term       -- type application t[T]
    | TmTApp Term Type              -- type abstraction (\lambda X.t) # X:type
    | TmZero
    | TmSucc Term 
    | TmPred Term
    | TmIsZero Term
    | TmInert Type
    | TmPack Type Term Type         -- {*T, t} as T
    | TmUnpack String String Term Term -- let {X, x} = t1 in t2
    | TmRef Term
    | TmDeref Term
    | TmAssign Term Term
    | TmError
    | TmTry Term Term
    | TmLoc Int
    deriving(Eq, Show)
    -- TmUpdate Term String Term
    
data Binding = 
    NameBinding
    | TyVarBinding Type                 -- \Gamma, x : T
    | VarBinding Type
    | TyAbbBinding Type             -- Or TyAbbBinding Type (Maybe Kind) \Gamma, X
    | TmAbbBinding Term (Maybe Type)    
    deriving(Eq, Show)
    
type Context = [(String, Binding)]

data Command = 
    Eval Term 
    | Bind String Binding
    | SomeBind String String Term

-- Context
addBinding :: Context -> String -> Binding -> Context
addBinding ctx x bind = (x, bind) : ctx

addName :: Context -> String -> Context
addName ctx x = addBinding ctx x NameBinding

isNameBound :: Context -> String -> Bool
isNameBound ctx x = case ctx of
    []   -> False
    y:ys -> if x == (fst y) then True else isNameBound ys x

pkFreshVarName :: Context -> String -> (String, Context)
pkFreshVarName ctx x =
    let x' = mkFreshVarName ctx x in
        (x', addBinding ctx x' NameBinding)

mkFreshVarName :: Context -> String -> String
mkFreshVarName [] x = x
mkFreshVarName ctx@(c:cs) x
    | x == (fst c)    = mkFreshVarName ctx (x ++ "'")
    | otherwise       = mkFreshVarName cs x

indexToName :: Context -> Int -> String
indexToName ctx i
    | length ctx > i = fst $ ctx !! i
    | otherwise      = undefined

nameToIndex :: Context -> String -> Int
nameToIndex ctx x = case ctx of
    []   -> undefined
    y:ys -> if x == (fst y) then 0 else (+) 1 $ nameToIndex ctx x

-- Shifting
-- instance Functor Type where
tyMap onvar c tyT = walk c tyT where
    walk c tyT = case tyT of
        TyVar x n            -> onvar c x n
        TyId b               -> TyId b
        TyArr tyT1 tyT2      -> TyArr (walk c tyT1) (walk c tyT2)
        TyTop                -> TyTop
        TyBot                -> TyBot
        TyBool               -> TyBool
        TyRecord fs          -> TyRecord $ map (\lty -> (fst lty, walk c $ snd lty)) fs
        TyVariant fs         -> TyVariant $ map (\lty -> (fst lty, walk c $ snd lty)) fs
        TyString             -> TyString
        TyUnit               -> TyUnit
        TyFloat              -> TyFloat
        TyAll tyX tyT1 tyT2  -> TyAll tyX (walk c tyT1) (walk c tyT2)
        TyNat                -> TyNat
        TySome tyX tyT1 tyT2 -> TySome tyX (walk c tyT1) (walk c tyT2)
        TyRef tyT1           -> TyRef (walk c tyT1)
        TySource tyT1        -> TySource (walk c tyT1)
        TySink tyT1          -> TySink (walk c tyT1)

tmMap onvar ontype c t = walk c t where
    walk c t = case t of
        TmInert tyT          -> TmInert $ ontype c tyT
        TmVar x n            -> onvar c x n
        TmAbs x tyT1 t2      -> TmAbs x (ontype c tyT1) (walk (c+1) t2)
        TmApp t1 t2          -> TmApp (walk c t1) (walk c t2)
        TmTrue               -> TmTrue
        TmFalse              -> TmFalse
        TmIf t1 t2 t3        -> TmIf (walk c t1) (walk c t2) (walk c t3)
        TmProj t1 l          -> TmProj (walk c t1) l
        TmRecord fs          -> TmRecord $ map (\lt -> (fst lt, walk c $ snd lt)) fs
        TmLet x t1 t2        -> TmLet x (walk c t1) (walk (c+1) t2)
        TmFix t1             -> TmFix (walk c t1)
        TmString x           -> TmString x
        TmUnit               -> TmUnit
        TmAscribe t1 tyT1    -> TmAscribe (walk c t1) (ontype c tyT1)
        TmFloat x            -> TmFloat x
        TmTimesFloat t1 t2   -> TmTimesFloat (walk c t1) (walk c t2)
        TmTAbs tyX tyT1 t2   -> TmTAbs tyX (ontype c tyT1) (walk (c+1) t2)
        TmTApp t1 tyT2       -> TmTApp (walk c t1) (ontype c tyT2)
        TmZero               -> TmZero
        TmSucc t1            -> TmSucc (walk c t1)
        TmPred t1            -> TmPred (walk c t1)
        TmIsZero t1          -> TmIsZero (walk c t1)
        TmPack tyT1 t2 tyT3  -> TmPack (ontype c tyT1) (walk c t2) (ontype c tyT3)
        TmUnpack tyX x t1 t2 -> TmUnpack tyX x (walk c t1) (walk (c+2) t2)
        TmTag l t1 tyT       -> TmTag l (walk c t1) (ontype c tyT)
        TmCase t cases       -> TmCase (walk c t) (map (\(li, (xi, ti)) -> (li, (xi, walk (c+1) ti))) cases)
        TmLoc l              -> TmLoc l
        TmRef t1             -> TmRef (walk c t1)
        TmDeref t1           -> TmDeref (walk c t1)
        TmAssign t1 t2       -> TmAssign (walk c t1) (walk c t2)
        TmError              -> TmError
        TmTry t1 t2          -> TmTry (walk c t1) (walk c t2)


typeShiftAbove d c tyT = 
    tyMap 
        (\c x n -> if x >= c then TyVar (x+d) (n+d) else TyVar x (n+d))
        c tyT

-- [↑d, c]t
termShiftAbove d c t = 
    tmMap
        (\c' x n -> if x >= c' then TmVar (x+d) (n+d) else TmVar x (n+d))
        (typeShiftAbove d)
        c t

typeShift d tyT = typeShiftAbove d 0 tyT

termShift d t = termShiftAbove d 0 t

bindingShift d bind = case bind of
    NameBinding -> NameBinding
    TyVarBinding tyS -> TyVarBinding (typeShift d tyS)
    VarBinding tyT -> VarBinding (typeShift d tyT)
    TyAbbBinding tyT -> TyAbbBinding (typeShift d tyT)
    TmAbbBinding t tyT_opt -> 
        let tyT_opt' = case tyT_opt of
                        Nothing  -> Nothing
                        Just tyT -> Just (typeShift d tyT)
        in TmAbbBinding (termShift d t) tyT_opt'

-- Substitution
-- [j -> s]t
termSubst j s t =
    tmMap
        (\j x n -> if x == j then termShift j s else TmVar x n)
        (\j tyT -> tyT)
        j t

typeSubst tyS j tyT =
    tyMap
        (\j x n -> if x == j then typeShift j tyS else TyVar x n)
        j tyT

termSubstTop s t = 
    termShift (-1) (termSubst 0 (termShift 1 s) t)

typeSubstTop tyS tyT = 
    typeShift (-1) (typeSubst (typeShift 1 tyS) 0 tyT)

tyTermSubst tyS j t =
    tmMap
        (\c x n -> TmVar x n)
        (\j tyT -> typeSubst tyS j tyT)
        j t

tyTermSubstTop tyS t =
    termShift (-1) (tyTermSubst (typeShift 1 tyS) 0 t)

-- Context
getBinding ctx i
    | length ctx > i = let bind = snd $ ctx !! i
                        in bindingShift (i + 1) bind
    | otherwise      = undefined

getTypeFromContext ctx i = 
    case getBinding ctx i of
        VarBinding tyT            -> tyT
        TmAbbBinding _ (Just tyT) -> tyT
        TmAbbBinding _ Nothing    -> undefined
        _                         -> undefined

-- Print
small t = case t of
    TmVar _ _ -> True
    _         -> False

-- TODO: printType / printTerm

-- Evaluation
isNumericVal ctx t = case t of
    TmZero    -> True
    TmSucc t1 -> isNumericVal ctx t1
    _         -> False

isVal ctx t = case t of
    TmTrue                 -> True
    TmFalse                -> True
    TmString _             -> True
    TmUnit                 -> True
    TmFloat _              -> True
    TmLoc _                -> True
    t | isNumericVal ctx t -> True
    TmAbs _ _ _            -> True
    TmRecord fs            -> all (\(l,ti) -> isVal ctx ti) fs
    TmPack _ v1 _          -> isVal ctx v1
    TmTAbs _ _ _           -> True
    _                      -> False

type Store = [Term]

extendStore store v = (length store, store ++ [v])

lookupLoc store l = store !! l

updateStore store n v = f (n, store) where
    f s = case s of
            (0, v':rest) -> v:rest
            (n, v':rest) -> v':f(n-1, rest)
            _            -> error "updateStore: bad index"

shiftStore i store = map (\t -> termShift i t) store

eval1 ctx store t = case t of
    TmIf TmTrue t2 t3  -> (t2, store)
    TmIf TmFalse t2 t3 -> (t3, store)
    TmIf t1 t2 t3      -> let (t1', store') = eval1 ctx store t1 in
        (TmIf t1' t2 t3, store')
    TmRecord fs -> 
        let evalField l = case l of
                            [] -> (error "No Rule Applies")
                            (l, vi):rest 
                                | isVal ctx vi -> let (rest', store') = evalField rest in
                                    ((l, vi):rest', store')
                                | otherwise    -> let (ti', store') = eval1 ctx store vi in
                                    ((l, ti'):rest, store')
        in let (fs', store') = evalField fs in 
            (TmRecord fs', store')
    TmProj (TmRecord fs) l
        | isVal ctx (TmRecord fs) -> let rd = filter (\(li, ti) -> li == l) fs in
            if rd == [] then (error "No Rule Applies") else (snd $ rd !! 0, store)
    TmProj t1 l                   -> let (t1', store') = eval1 ctx store t1 in
            (TmProj t1' l, store')
    TmLet x v1 t2
        | isVal ctx v1 -> (termSubstTop v1 t2, store)
        | otherwise    -> let (t1', store') = eval1 ctx store v1 in
            (TmLet x t1' t2, store')
    TmFix v1
        | isVal ctx v1 -> case v1 of
            TmAbs _ _ t12 -> (termSubstTop (TmFix v1) t12, store)
            _             -> (error "No Rule Applies")
        | otherwise    -> let (t1', store') = eval1 ctx store v1 in
            (TmFix t1', store')
    TmTag l t1 tyT -> let (t1', store') = eval1 ctx store t1 in
        (TmTag l t1' tyT, store')
    TmCase (TmTag li v11 tyT) branches
        | isVal ctx v11 -> let rd = filter (\(li', (xi, ti)) -> li == li') branches in
            if rd == [] then (error "No Rule Applies") else (termSubstTop v11 $ snd $ snd (rd !! 0), store)
    TmCase t1 branches -> let (t1', store') = eval1 ctx store t1 in
        (TmCase t1' branches, store')
    TmAscribe v1 tyT
        | isVal ctx v1 -> (v1, store)
        | otherwise    -> let (t1', store') = eval1 ctx store v1 in
            (TmAscribe t1' tyT, store')
    TmVar n _ -> case getBinding ctx n of
        TmAbbBinding t _ -> (t, store)
        _                -> (error "No Rule Applies")
    TmRef t1
        | isVal ctx t1 -> let (l, store') = extendStore store t1 in
            (TmLoc l, store')
        | otherwise    -> let (t1', store') = eval1 ctx store t1 in
            (TmRef t1', store')
    TmDeref t1
        | isVal ctx t1 -> case t1 of
            TmLoc l -> (lookupLoc store l, store)
            _       -> (error "No Rule Applies")
        | otherwise    -> let (t1', store') = eval1 ctx store t1 in
            (TmDeref t1', store')
    TmAssign t1 t2
        | (isVal ctx t1) && (isVal ctx t2) -> case t1 of
            TmLoc l -> (TmUnit, updateStore store l t2)
            _       -> (error "No Rule Applies")
        | not (isVal ctx t1)               -> let (t1', store') = eval1 ctx store t1 in
            (TmAssign t1' t2, store')
        | not (isVal ctx t2)               -> let (t2', store') = eval1 ctx store t2 in
            (TmAssign t1 t2', store')
    TmError -> (error "Error Encountered")
    TmTimesFloat (TmFloat f1) (TmFloat f2) -> (TmFloat (f1*f2), store)
    TmTimesFloat (TmFloat f1) t2           -> let (t2', store') = eval1 ctx store t2 in
        (TmTimesFloat (TmFloat f1) t2', store')
    TmTimesFloat t1 t2                     -> let (t1', store') = eval1 ctx store t1 in
        (TmTimesFloat t1' t2, store')
    TmSucc t1 -> let (t1', store') = eval1 ctx store t1 in
        (TmSucc t1', store')
    TmPred t1 -> let (t1', store') = eval1 ctx store t1 in
        (TmPred t1', store')
    TmIsZero TmZero            -> (TmTrue, store)
    TmIsZero (TmSucc nv1)
        | isNumericVal ctx nv1 -> (TmFalse, store)
    TmIsZero t1                -> let (t1', store') = eval1 ctx store t1 in
        (TmIsZero t1', store')
    TmTApp (TmTAbs x _ t11) tyT2 -> (tyTermSubstTop tyT2 t11, store)
    TmTApp t1 tyT2               -> let (t1', store') = eval1 ctx store t1 in
        (TmTApp t1' tyT2, store')
    TmApp (TmAbs x tyT11 t12) v2
        | isVal ctx v2 -> (termSubstTop v2 t12, store)
    TmApp v1 t2
        | isVal ctx v1 -> let (t2', store') = eval1 ctx store t2 in
            (TmApp v1 t2', store')
    TmApp t1 t2 -> let (t1', store') = eval1 ctx store t2 in
        (TmApp t1' t2, store')
    TmPack tyT1 t2 tyT3 -> let (t2', store') = eval1 ctx store t2 in
        (TmPack tyT1 t2' tyT3, store')
    TmUnpack _ _ (TmPack tyT11 v12 _) t2
        | isVal ctx v12 -> (tyTermSubstTop tyT11 (termSubstTop (termShift 1 v12) t2), store)
    TmUnpack tyX x t1 t2 -> let (t1', store') = eval1 ctx store t1 in
        (TmUnpack tyX x t1' t2, store')

-- By process and perservation theorem
evalPre ctx store t = unsafePerformIO $ catch
    (evaluate $ eval1 ctx store t)
    returnTs
    where
        returnTs :: SomeException -> IO (Term, Store)
        returnTs err = return (t, store)

eval ctx store t = let (t', store') = evalPre ctx store t in
    if (t', store') == (t, store) 
        then (t, store) 
        else evalPre ctx store' t'

-- Subtying
evalBinding ctx store b = case b of
    TmAbbBinding t tyT -> let (t', store') = eval ctx store t in
        (TmAbbBinding t' tyT, store')
    bind               -> (bind, store)

promote ctx t = case t of                               -- \Gamma |- S ⇑ T (T是S的最小不变超类型)
    TyVar i _ -> case getBinding ctx i of
        TyVarBinding tyT -> tyT
        _                -> (error "No Rule Applies")
    _         -> (error "No Rule Applies")

isTyAbb ctx i = case getBinding ctx i of
    TyAbbBinding tyT -> True
    _                -> False

getTyAbb ctx i = case getBinding ctx i of
    TyAbbBinding tyT -> tyT
    _                -> (error "No Rule Applies")

computeTy ctx tyT = case tyT of
    TyVar i _ | isTyAbb ctx i -> getTyAbb ctx i
    _                         -> (error "No Rule Applies")

-- That's all bad
simplifyTy1 :: Context -> Type -> Type
simplifyTy1 ctx tyT = unsafePerformIO $ catch
    (evaluate (computeTy ctx tyT))
    returnTy
    where
        returnTy :: SomeException -> IO Type
        returnTy err = return tyT

simplifyTy ctx tyT = let tyT' = simplifyTy1 ctx tyT in
    if tyT' == tyT then tyT else simplifyTy1 ctx tyT'

tyEqv ctx tyS tyT = 
    let tyS' = simplifyTy ctx tyS
        tyT' = simplifyTy ctx tyT
    in case (tyS', tyT') of
        (TyTop, TyTop) -> True
        (TyBot, TyBot) -> True
        (TyArr tyS1 tyS2, TyArr tyT1 tyT2) ->
            (tyEqv ctx tyS1 tyT1) && (tyEqv ctx tyS2 tyT2)
        (TyString, TyString) -> True
        (TyId b1, TyId b2) -> b1 == b2
        (TyFloat, TyFloat) -> True
        (TyUnit, TyUnit) -> True
        (TyRef tyT1, TyRef tyT2) -> tyEqv ctx tyT1 tyT2
        (TySource tyT1, TySource tyT2) -> tyEqv ctx tyT1 tyT2
        (TySink tyT1, TySink tyT2) -> tyEqv ctx tyT1 tyT2
        (TyVar i _, _) | isTyAbb ctx i -> tyEqv ctx (getTyAbb ctx i) tyT'
        (_, TyVar i _) | isTyAbb ctx i -> tyEqv ctx tyS' (getTyAbb ctx i)
        (TyBool, TyBool) -> True
        (TyNat, TyNat) -> True
        (TyRecord fs1, TyRecord fs2) -> (length fs1 == length fs2) &&
            all id (map
                (\(li2, tyTi2) -> let rd = filter (\(li1, tyTi1) -> li2 == li1) fs1
                                in if length rd == 0 then False else tyEqv ctx (snd $ rd !! 0) tyTi2
                )
            fs2)
        (TyAll tyX1 tyS1 tyS2, TyAll _ tyT1 tyT2) -> let ctx' = addName ctx tyX1 in
            (tyEqv ctx tyS1 tyT1) && (tyEqv ctx' tyS2 tyT2)
        (TyVariant fs1, TyVariant fs2) -> (length fs1 == length fs2) &&
            all id (map
                (\(li2, tyTi2) -> let rd = filter (\(li1, tyTi1) -> li2 == li1) fs1
                                in if length rd == 0 then False else tyEqv ctx (snd $ rd !! 0) tyTi2
                )
            fs2)
        _ -> False

subtype ctx tyS tyT = tyEqv ctx tyS tyT ||
    let tyS' = simplifyTy ctx tyS
        tyT' = simplifyTy ctx tyT
    in case (tyS', tyT') of
        -- T <: Top
        (_, TyTop) -> True
        -- Bot <: T
        (TyBot, _) -> True
        -- (->) a as contravariant operatior
        (TyArr tyS1 tyS2, TyArr tyT1 tyT2) -> 
            (subtype ctx tyT1 tyS1) && (subtype ctx tyS2 tyT2)
        -- {l:r} <: {l':r'}
        (TyRecord fS, TyRecord fT) ->
            all id (map
                (\(li, tyTi) -> let rd = filter (\(li1, tyTi1) -> li == li1) fS
                                in if length rd == 0 then False else subtype ctx (snd $ rd !! 0) tyTi)
                fT
            )
        (TyVariant fS, TyVariant fT) ->
            all id (map
                (\(li, tyTi) -> let rd = filter (\(li1, tyTi1) -> li == li1) fS
                                in if length rd == 0 then False else subtype ctx (snd $ rd !! 0) tyTi)
                fT
            )
        (TyVar _ _, _) -> subtype ctx (promote ctx tyS') tyT'
        (TyAll tyX1 tyS1 tyS2, TyAll _ tyT1 tyT2) -> 
            (subtype ctx tyS1 tyT1 && subtype ctx tyT1 tyS1) &&
            let ctx' = addBinding ctx tyX1 (TyVarBinding tyT1) in
                subtype ctx' tyS2 tyT2
        (TyRef tyT1, TyRef tyT2) -> (subtype ctx tyT1 tyT2) && (subtype ctx tyT2 tyT1)
        (TyRef tyT1, TySource tyT2) -> subtype ctx tyT1 tyT2
        (TySource tyT1, TySource tyT2) -> subtype ctx tyT1 tyT2
        (TyRef tyT1, TySink tyT2) -> subtype ctx tyT2 tyT1
        (TySink tyT1, TySink tyT2) -> subtype ctx tyT2 tyT1
        _ -> False
    
join ctx tyS tyT = 
    if subtype ctx tyS tyT then tyT else
        if subtype ctx tyT tyS then tyS else
            let tyS' = simplifyTy ctx tyS
                tyT' = simplifyTy ctx tyT
            in case (tyS', tyT') of
                (TyRecord fS, TyRecord fT) -> 
                    let labelsS = map (\(li, t) -> li) fS
                        labelsT = map (\(li, t) -> li) fT
                        commonLabels = filter (\li -> elem li labelsT) labelsS
                        commonFields = map (\li -> (li, join ctx (fromJust $ lookup li fS) (fromJust $ lookup li fT))) commonLabels
                    in TyRecord commonFields
                (TyAll tyX tyS1 tyS2, TyAll _ tyT1 tyT2) ->
                    if not $ (subtype ctx tyS1 tyT1) && (subtype ctx tyT1 tyS1)
                        then TyTop
                        else let ctx' = addBinding ctx tyX (TyVarBinding tyT1) in
                            TyAll tyX tyS1 (join ctx' tyT1 tyT2)
                (TyArr tyS1 tyS2, TyArr tyT1 tyT2) ->
                    TyArr (meet ctx tyS1 tyT1) (join ctx tyS2 tyT2)
                (TyRef tyT1, TyRef tyT2) ->
                    if (subtype ctx tyT1 tyT2) && (subtype ctx tyT2 tyT1)
                        then TyRef tyT1
                        else TySource (join ctx tyT1 tyT2) -- why incomplete
                (TySource tyT1, TySource tyT2) -> TySource (join ctx tyT1 tyT2)
                (TyRef tyT1, TySource tyT2) -> TySource (join ctx tyT1 tyT2)
                (TySource tyT1, TyRef tyT2) -> TySource (join ctx tyT1 tyT2)
                (TySink tyT1, TySink tyT2) -> TySink (meet ctx tyT1 tyT2)
                (TyRef tyT1, TySink tyT2) -> TySink (meet ctx tyT1 tyT2)
                (TySink tyT1, TyRef tyT2) -> TySink (meet ctx tyT1 tyT2)
                _ -> TyTop

meet ctx tyS tyT = 
    if subtype ctx tyS tyT then tyS else
        if subtype ctx tyT tyS then tyT else
            let tyS' = simplifyTy ctx tyS
                tyT' = simplifyTy ctx tyT
            in case (tyS', tyT') of
                (TyRecord fS, TyRecord fT) -> 
                    let labelsS = map (\(li, t) -> li) fS
                        labelsT = map (\(li, t) -> li) fT
                        allLabels = union labelsS labelsT
                        allFields = map (\li -> 
                                        if (elem li labelsS) && (elem li labelsT)
                                            then (li, meet ctx (fromJust $ lookup li fS) (fromJust $ lookup li fT))
                                            else if elem li labelsS
                                                then (li, fromJust $ lookup li fS)
                                                else (li, fromJust $ lookup li fT)
                                    ) allLabels
                    in TyRecord allFields
                (TyAll tyX tyS1 tyS2, TyAll _ tyT1 tyT2) ->
                    if not $ (subtype ctx tyS1 tyT1) && (subtype ctx tyT1 tyS1)
                        then error "Not Found"
                        else let ctx' = addBinding ctx tyX (TyVarBinding tyT1) in
                            TyAll tyX tyS1 (meet ctx' tyT1 tyT2)
                (TyArr tyS1 tyS2, TyArr tyT1 tyT2) ->
                    TyArr (join ctx tyS1 tyT1) (meet ctx tyS2 tyT2)
                (TyRef tyT1, TyRef tyT2) ->
                    if (subtype ctx tyT1 tyT2) && (subtype ctx tyT2 tyT1)
                        then TyRef tyT1
                        else TySource (meet ctx tyT1 tyT2) -- why incomplete
                (TySource tyT1, TySource tyT2) -> TySource (meet ctx tyT1 tyT2)
                (TyRef tyT1, TySource tyT2) -> TySource (meet ctx tyT1 tyT2)
                (TySource tyT1, TyRef tyT2) -> TySource (meet ctx tyT1 tyT2)
                (TySink tyT1, TySink tyT2) -> TySink (join ctx tyT1 tyT2)
                (TyRef tyT1, TySink tyT2) -> TySink (join ctx tyT1 tyT2)
                (TySink tyT1, TyRef tyT2) -> TySink (join ctx tyT1 tyT2)
                _ -> TyBot

-- Typing
lcst1 ctx tyS = unsafePerformIO $ catch
    (evaluate $ promote ctx tyS)
    returnTy
    where
        returnTy :: SomeException -> IO Type
        returnTy err = return tyS

lcst ctx tyS = let tyS' = lcst1 ctx tyS in
    if tyS' == tyS
        then tyS
        else lcst1 ctx tyS

typeOf ctx t = case t of
    TmInert tyT -> tyT
    TmVar i _ -> getTypeFromContext ctx i
    TmAbs x tyT1 t2 -> let ctx' = addBinding ctx x (VarBinding tyT1)
                           tyT2 = typeOf ctx' t2
                       in TyArr tyT1 (typeShift (-1) tyT2)
    TmApp t1 t2 -> let tyT1 = typeOf ctx t1
                       tyT2 = typeOf ctx t2
                   in case lcst ctx tyT1 of
                        TyArr tyT11 tyT12 -> 
                            if subtype ctx tyT2 tyT11 then tyT12 else (error "Parameter type mismatch")
                        TyBot             -> TyBot
                        _                 -> (error "Arrow type expected")
    TmTrue  -> TyBool
    TmFalse -> TyBool
    TmIf t1 t2 t3 -> if subtype ctx (typeOf ctx t1) TyBool
                        then join ctx (typeOf ctx t2) (typeOf ctx t3)
                        else (error "Guard of conditional not a boolean")
    TmLet x t1 t2 -> let tyT1 = typeOf ctx t1
                         ctx' = addBinding ctx x (VarBinding tyT1)
                     in typeShift (-1) (typeOf ctx' t2)
    TmRecord fs -> let ftys = map (\(li, ti) -> (li, typeOf ctx ti)) fs in
         TyRecord ftys
    TmProj t1 l -> case lcst ctx (typeOf ctx t1) of
        TyRecord ftys -> case lookup l ftys of
            Just tys -> tys
            Nothing  -> (error $ "Label " ++ l ++ " not found")
        TyBot         -> TyBot
        _             -> (error "Expected record type")
    TmCase t cases -> case lcst ctx (typeOf ctx t) of
        TyVariant ftys -> let _ = map (\(li, (xi, ti)) -> case lookup li ftys of
                                        Just _  -> ()
                                        Nothing -> (error $ "Label " ++ li ++ " not in type")
                                    ) cases
                              casetys = map (\(li, (xi, ti)) -> case lookup li ftys of
                                            Nothing -> undefined -- impossible!
                                            Just tyTi -> let ctx' = addBinding ctx xi (VarBinding tyTi) in
                                                typeShift (-1) (typeOf ctx' ti)
                                        ) cases
                          in foldl (join ctx) TyBot casetys
        TyBot          -> TyBot
        _              -> (error "Expected variant type")
    TmFix t1 -> let tyT1 = typeOf ctx t1 in
        case lcst ctx tyT1 of
            TyArr tyT11 tyT12 -> if subtype ctx tyT12 tyT11 
                                    then tyT12
                                    else (error "Result of body not compatible with domain")
            TyBot             -> TyBot
            _                 -> (error "Arrow type expected")
    TmTag li ti tyT -> case simplifyTy ctx tyT of
        TyVariant ftys -> let tyTiExpected = lookup li ftys
                              tyTi = typeOf ctx ti
                          in case tyTiExpected of
                            Nothing    -> (error $ "Label " ++ li ++ " not found")
                            Just tyTie -> if subtype ctx tyTi tyTie
                                            then tyT
                                            else (error "Field does not have expected type")
    TmAscribe t1 tyT -> if subtype ctx (typeOf ctx t1) tyT
                            then tyT
                            else (error "Body of as-term does not have the expected type")
    TmString _ -> TyString
    TmUnit     -> TyUnit
    TmRef t1   -> TyRef (typeOf ctx t1)
    TmLoc l    -> (error "Locations are not supposed to occur in source programs")
    TmDeref t1 -> case lcst ctx (typeOf ctx t1) of
        TyRef tyT1    -> tyT1
        TyBot         -> TyBot
        TySource tyT1 -> tyT1
        _             -> (error "Argument of ! is not a Ref or Source")
    TmAssign t1 t2 -> case lcst ctx (typeOf ctx t1) of
        TyRef tyT1  -> if subtype ctx (typeOf ctx t2) tyT1
                        then TyUnit
                        else (error "Arguments of := are incompatible")
        TyBot       -> let _ = typeOf ctx t2 in TyBot
        TySink tyT1 -> if subtype ctx (typeOf ctx t2) tyT1
                        then TyUnit
                        else (error "Arguments of := are incompatible")
        _           -> (error "Argument of := is not a Ref or Sink")
    TmError         -> TyBot
    TmFloat _       -> TyFloat
    TmTimesFloat t1 t2 -> if (subtype ctx (typeOf ctx t1) TyFloat) && (subtype ctx (typeOf ctx t2) TyFloat)
                            then TyFloat
                            else (error "Argument of *f is not a float") -- consider number <: float ?
    TmTAbs tyX tyT1 t2 -> let ctx' = addBinding ctx tyX (TyVarBinding tyT1)
                              tyT2 = typeOf ctx t2
                          in TyAll tyX tyT1 tyT2
    TmTApp t1 tyT2     -> let tyT1 = typeOf ctx t1 in
        case lcst ctx tyT1 of
            TyAll _ tyT11 tyT12 -> if not $ subtype ctx tyT2 tyT11
                                    then (error "Type parameter type mismatch")
                                    else typeSubstTop tyT2 tyT12
            _                   -> (error "Universal type expected")
    TmTry t1 t2 -> join ctx (typeOf ctx t1) (typeOf ctx t2)
    TmZero      -> TyNat
    TmSucc t1   -> if subtype ctx (typeOf ctx t1) TyNat
                    then TyNat
                    else (error "Argument of succ is not a number")
    TmPred t1   -> if subtype ctx (typeOf ctx t1) TyNat
                    then TyNat
                    else (error "Argument of pred is not a number")
    TmIsZero t1 -> if subtype ctx (typeOf ctx t1) TyNat
                    then TyBool
                    else (error "Argument of iszero is not a number")
    TmPack tyT1 t2 tyT -> case simplifyTy ctx tyT of
        TySome tyY tyBound tyT2 -> if not $ subtype ctx tyT1 tyBound
                                    then (error "Hidden type not a subtype of bound")
                                    else let tyU = typeOf ctx t2
                                             tyU' = typeSubstTop tyT1 tyT2
                                    in if subtype ctx tyU tyU'
                                        then tyT
                                        else (error "Doesn't match declared type")
        _                       -> (error "Existential type expected")
    TmUnpack tyX x t1 t2 -> let tyT1 = typeOf ctx t1 in 
        case lcst ctx tyT1 of
            TySome tyT tyBound tyT11 -> let ctx' = addBinding ctx tyX (TyVarBinding tyBound)
                                            ctx'' = addBinding ctx' x (VarBinding tyT11)
                                            tyT2 = typeOf ctx'' t2
                                        in typeShift (-2) tyT2
            _                        -> (error "Existential type expected")