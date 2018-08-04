{-# LANGUAGE TypeFamilies #-}
module Text.Seonbi.Html.TagStack
    ( HtmlTagStack
    , Text.Seonbi.Html.TagStack.any
    , descendsFrom
    , Text.Seonbi.Html.TagStack.elem
    , empty
    , fromList
    , pop
    , push
    , toList
    ) where

import Data.List
import GHC.Exts (IsList (..))

import Text.Seonbi.Html.Tag

-- | Represents a hierarchy of a currently parsing position in an 'HtmlTag'
-- tree.
--
-- For example, if an 'scanHtml' has read "@\<a href="#">\<b>\<i>foo\</i> bar@"
-- it is represented as @'HtmlTagStack' ['B', 'A']@.
--
-- Note that the tags are stored in reverse order, from the deepest to
-- the shallowest, to make inserting a more deeper tag efficient.
newtype HtmlTagStack = HtmlTagStack [HtmlTag] deriving (Eq, Ord)

instance IsList HtmlTagStack where
    type Item HtmlTagStack = HtmlTag
    fromList = HtmlTagStack . reverse
    toList (HtmlTagStack tags) = reverse tags

instance Show HtmlTagStack where
    show tags = "fromList " ++ show (toList tags)

-- | An empty stack.
empty :: HtmlTagStack
empty = HtmlTagStack []

-- | Push one deeper @tag@ to a 'HtmlTagStack'.
--
-- >>> push A empty
-- fromList [A]
-- >>> push B (push A empty)
-- fromList [A,B]
push :: HtmlTag -> HtmlTagStack -> HtmlTagStack
push tag (HtmlTagStack tags) =
    HtmlTagStack (tag : tags)

-- | Pop the deepest @tag@ from a 'HtmlTagStack'.
--
-- >>> :set -XOverloadedLists
-- >>> pop Em [A, B, Em]
-- fromList [A,B]
--
-- It may pop a @tag@ in the middle if a @tag@ looking for is not the deepest:
--
-- >>> pop B [A, B, Em]
-- fromList [A,Em]
--
-- It does not affect to the input if there is no such @tag@ in the input:
--
-- >>> pop P [A, B, Em]
-- fromList [A,B,Em]
-- >>> pop A empty
-- fromList []
pop :: HtmlTag -> HtmlTagStack -> HtmlTagStack
pop tag (HtmlTagStack tags'@(t : ags)) =
    if t == tag
         then HtmlTagStack ags
         else
            let
                (head', rest) = span (/= tag) tags'
                tail' = case uncons rest of
                    Just (_, tail'') -> tail''
                    Nothing -> []
            in
                HtmlTagStack (head' ++ tail')
pop _ (HtmlTagStack []) = empty

-- | Check if a node ('HtmlEntity') that a 'HtmlTagStack' (the first argument) 
-- refers is contained by a node that another 'HtmlTagStack' (the second
-- argument), or they are sibling at least.
--
-- >>> :set -XOverloadedLists
-- >>> descendsFrom [Div, P, A, Em] [Div, P, A]
-- True
-- >>> descendsFrom [Div, P, A] [Div, P, A]
-- True
-- >>> descendsFrom [Div, P, Em] [Div, P, A]
-- False
-- >>> descendsFrom [Div, P] [Div, P, A]
-- False
descendsFrom :: HtmlTagStack -> HtmlTagStack -> Bool
HtmlTagStack a `descendsFrom` HtmlTagStack b =
    b `isSuffixOf` a

-- | Determine whether any element of the tag stack satisfies the predicate.
--
-- >>> :set -XOverloadedLists
-- >>> Text.Seonbi.Html.TagStack.any ((== Void) . htmlTagKind) [Div, P, Script]
-- False
-- >>> Text.Seonbi.Html.TagStack.any ((== Void) . htmlTagKind) [BR, P, Script]
-- True
any :: (HtmlTag -> Bool) -> HtmlTagStack -> Bool
any fn (HtmlTagStack stack) =
    Prelude.any fn stack

-- | Determine whether the element occurs in the tag stack.
--
-- >>> :set -XOverloadedLists
-- >>> A `Text.Seonbi.Html.TagStack.elem` [A, B, Code]
-- True
-- >>> Em `Text.Seonbi.Html.TagStack.elem` [A, B, Code]
-- False
elem :: HtmlTag -> HtmlTagStack -> Bool
elem tag (HtmlTagStack stack) = tag `Prelude.elem` stack
