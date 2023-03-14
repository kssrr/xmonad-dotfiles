-- xmonad.hs

-- Imports:

-- Base
import XMonad
import Data.Monoid
import System.Exit
import Graphics.X11.ExtraTypes.XF86

-- Layouts
import XMonad.Layout.NoBorders 

-- Utils
import XMonad.Util.SpawnOnce

-- Hooks
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.EwmhDesktops
import XMonad.Hooks.WindowSwallowing

import qualified XMonad.StackSet as W
import qualified Data.Map        as M

myTerminal      = "urxvt"

myFocusFollowsMouse :: Bool
myFocusFollowsMouse = True

myClickJustFocuses :: Bool
myClickJustFocuses = False

myBorderWidth   = 3
myModMask       = mod4Mask
myWorkspaces    = ["1","2","3","4","5","6","7","8","9"]
myNormalBorderColor  = "#dddddd"
myFocusedBorderColor = "#3579a8"

myKeys conf@(XConfig {XMonad.modMask = modm}) = M.fromList $
    [ ((modm .|. shiftMask, xK_Return), spawn $ XMonad.terminal conf),
      ((0, xF86XK_AudioMute), spawn "pactl set-sink-mute @DEFAULT_SINK@ toggle"),
      ((0, xF86XK_AudioLowerVolume), spawn "pactl set-sink-volume @DEFAULT_SINK@ -10%"),
      ((0, xF86XK_AudioRaiseVolume), spawn "pactl set-sink-volume @DEFAULT_SINK@ +10%"),
      ((0, xF86XK_AudioMicMute), spawn "pactl set-source-mute @DEFAULT_SOURCE@ toggle"),
      ((0, xF86XK_MonBrightnessUp), spawn "brightnessctl set +5%"),
      ((0, xF86XK_MonBrightnessDown), spawn "brightnessctl set 5%-"),
      ((0, xK_Print), spawn "scrot -s"),
      ((modm, 		    xK_r     ), spawn "rofi -show drun"),
      ((modm .|. shiftMask, xK_p     ), spawn "gmrun"),
      ((modm .|. shiftMask, xK_c     ), kill),
      ((modm,               xK_space ), sendMessage NextLayout),
      ((modm .|. shiftMask, xK_space ), setLayout $ XMonad.layoutHook conf),
      ((modm,               xK_n     ), refresh),
      ((modm,               xK_Tab   ), windows W.focusDown),
      ((modm,               xK_j     ), windows W.focusDown),
      ((modm,               xK_k     ), windows W.focusUp  ),
      ((modm,               xK_m     ), windows W.focusMaster  ),
      ((modm,               xK_Return), windows W.swapMaster),
      ((modm .|. shiftMask, xK_j     ), windows W.swapDown  ),
      ((modm .|. shiftMask, xK_k     ), windows W.swapUp    ),
      ((modm,               xK_h     ), sendMessage Shrink), -- resize: shrink master area
      ((modm,               xK_l     ), sendMessage Expand), -- resize: expand master area
      ((modm,               xK_t     ), withFocused $ windows . W.sink), -- set window to tiling
      ((modm              , xK_comma ), sendMessage (IncMasterN 1)),
      ((modm              , xK_period), sendMessage (IncMasterN (-1))),
      ((modm .|. shiftMask, xK_q     ), io (exitWith ExitSuccess)), -- quit xmonad
      ((modm              , xK_q     ), spawn "xmonad --recompile; xmonad --restart"), -- restart xmonad
      ((modm .|. shiftMask, xK_slash ), spawn ("echo \"" ++ help ++ "\" | xmessage -file -"))
    ]
    ++

    [((m .|. modm, k), windows $ f i)
        | (i, k) <- zip (XMonad.workspaces conf) [xK_1 .. xK_9],
          (f, m) <- [(W.greedyView, 0), (W.shift, shiftMask)]]
    ++

    --
    -- mod-{w,e,p}, Switch to physical/Xinerama screens 1, 2, or 3
    -- mod-shift-{w,e,p}, Move client to screen 1, 2, or 3
    --
    [((m .|. modm, key), screenWorkspace sc >>= flip whenJust (windows . f))
        | (key, sc) <- zip [xK_w, xK_e, xK_p] [0..], 
          (f, m) <- [(W.view, 0), (W.shift, shiftMask)]]

-- Mouse bindings:
myMouseBindings (XConfig {XMonad.modMask = modm}) = M.fromList $
    -- mod-button1, Set the window to floating mode and move by dragging:
    [ ((modm, button1), (\w -> focus w >> mouseMoveWindow w
                                       >> windows W.shiftMaster)),
    -- mod-button2, Raise the window to the top of the stack:
      ((modm, button2), (\w -> focus w >> windows W.shiftMaster)),
    -- mod-button3, Set the window to floating mode and resize by dragging:
      ((modm, button3), (\w -> focus w >> mouseResizeWindow w
                                       >> windows W.shiftMaster))
    ]

-- Layouts:
myLayout = tiled ||| Mirror tiled ||| noBorders Full
  where
     -- default tiling algorithm partitions the screen into two panes
     tiled   = Tall nmaster delta ratio
     -- The default number of windows in the master pane
     nmaster = 1
     -- Default proportion of screen occupied by master pane
     ratio   = 1/2
     -- Percent of screen to increment by when resizing panes
     delta   = 3/100

-- Window rules:
myManageHook = composeAll
    [ className =? "MPlayer"        --> doFloat,
      className =? "Gimp"           --> doFloat,
      className =? "Steam"          --> doFloat,
      className =? "TeamSpeak 3"    --> doFloat,
      resource  =? "desktop_window" --> doIgnore,
      resource  =? "kdesktop"       --> doIgnore ]

-- Event handling
myEventHook = swallowEventHook (className =? "URxvt") (return True)

-- Status bars and logging
myLogHook = return ()

-- Startup hook
myStartupHook :: X()
myStartupHook = do
	spawnOnce "nitrogen --restore &"

-- Command to launch the bar.
myBar = "xmobar"

-- Custom PP, configure it as you like. It determines what is being written to the bar.
myPP = xmobarPP {ppCurrent = xmobarColor "#429942" "" . wrap "[" "]",
                 ppTitle = xmobarColor "#429942" "" . shorten 50,
                 ppLayout = xmobarColor "grey" "" . myLayoutPrinter}

myLayoutPrinter :: String -> String
myLayoutPrinter "Tall" = "[]="
myLayoutPrinter "Mirror Tall" = "[|]"
myLayoutPrinter "Full" = "<[]>"
myLayoutPrinter x = x

-- Key binding to toggle the gap for the bar.
toggleStrutsKey XConfig {XMonad.modMask = modMask} = (modMask, xK_b)


-- Main
main :: IO()
main = xmonad .
       ewmhFullscreen .
       ewmh =<<
       statusBar myBar myPP toggleStrutsKey defaults

-- alternatively:
-- main = xmonad =<< statusBar myBar myPP toggleStrutsKey defaults

-- defaults
defaults = def {
      -- simple stuff
        terminal           = myTerminal,
        focusFollowsMouse  = myFocusFollowsMouse,
        clickJustFocuses   = myClickJustFocuses,
        borderWidth        = myBorderWidth,
        modMask            = myModMask,
        workspaces         = myWorkspaces,
        normalBorderColor  = myNormalBorderColor,
        focusedBorderColor = myFocusedBorderColor,

      -- key bindings
        keys               = myKeys,
        mouseBindings      = myMouseBindings,

      -- hooks, layouts
        layoutHook         = myLayout,
        manageHook         = myManageHook,
        handleEventHook    = myEventHook,
        logHook            = myLogHook,
        startupHook        = myStartupHook
}

-- Help strings:
help :: String
help = unlines ["The default modifier key is 'super' (Windows-key). Default keybindings:",
    "",
    "-- launching and killing programs",
    "mod-Shift-Enter  Launch urxvt",
    "mod-r            Launch rofi",
    "mod-Shift-c      Close/kill the focused window",
    "mod-Space        Rotate through the available layout algorithms",
    "mod-Shift-Space  Reset the layouts on the current workSpace to default",
    "",
    "-- move focus up or down the window stack",
    "mod-Tab        Move focus to the next window",
    "mod-j          Move focus to the next window",
    "mod-k          Move focus to the previous window",
    "mod-m          Move focus to the master window",
    "",
    "-- modifying the window order",
    "mod-Return   Swap the focused window and the master window",
    "mod-Shift-j  Swap the focused window with the next window",
    "mod-Shift-k  Swap the focused window with the previous window",
    "",
    "-- resizing the master/slave ratio",
    "mod-h  Shrink the master area",
    "mod-l  Expand the master area",
    "",
    "-- floating layer support",
    "mod-t  Push window back into tiling; unfloat and re-tile it",
    "",
    "-- increase or decrease number of windows in the master area",
    "mod-comma  (mod-,)   Increment the number of windows in the master area",
    "mod-period (mod-.)   Deincrement the number of windows in the master area",
    "",
    "-- quit, or restart",
    "mod-Shift-q  Quit xmonad",
    "mod-q        Restart xmonad",
    "mod-[1..9]   Switch to workSpace N",
    "",
    "-- Workspaces & screens",
    "mod-Shift-[1..9]   Move client to workspace N",
    "mod-{w,e,p}        Switch to physical/Xinerama screens 1, 2, or 3",
    "mod-Shift-{w,e,p}  Move client to screen 1, 2, or 3",
    "",
    "-- Mouse bindings: default actions bound to mouse events",
    "mod-button1  Set the window to floating mode and move by dragging",
    "mod-button2  Raise the window to the top of the stack",
    "mod-button3  Set the window to floating mode and resize by dragging"]
