module Matterhorn.Events.ReactionEmojiListOverlay
  ( onEventReactionEmojiListOverlay
  , reactionEmojiListOverlayKeybindings
  , reactionEmojiListOverlayKeyHandlers
  )
where

import           Prelude ()
import           Matterhorn.Prelude

import qualified Graphics.Vty as Vty

import           Matterhorn.Events.Keybindings
import           Matterhorn.State.ReactionEmojiListOverlay
import           Matterhorn.State.ListOverlay
import           Matterhorn.Types


onEventReactionEmojiListOverlay :: Vty.Event -> MH ()
onEventReactionEmojiListOverlay =
    void . onEventListOverlay csReactionEmojiListOverlay reactionEmojiListOverlayKeybindings

-- | The keybindings we want to use while viewing an emoji list overlay
reactionEmojiListOverlayKeybindings :: KeyConfig -> KeyHandlerMap
reactionEmojiListOverlayKeybindings = mkKeybindings reactionEmojiListOverlayKeyHandlers

reactionEmojiListOverlayKeyHandlers :: [KeyEventHandler]
reactionEmojiListOverlayKeyHandlers =
    [ mkKb CancelEvent "Close the emoji search window" (exitListOverlay csReactionEmojiListOverlay)
    , mkKb SearchSelectUpEvent "Select the previous emoji" reactionEmojiListSelectUp
    , mkKb SearchSelectDownEvent "Select the next emoji" reactionEmojiListSelectDown
    , mkKb PageDownEvent "Page down in the emoji list" reactionEmojiListPageDown
    , mkKb PageUpEvent "Page up in the emoji list" reactionEmojiListPageUp
    , mkKb ActivateListItemEvent "Post the selected emoji reaction" (listOverlayActivateCurrent csReactionEmojiListOverlay)
    ]
