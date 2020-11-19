import { Maybe, Result } from "../Basics/Basics"
import { User } from "User"

/** To define what can happen.
 */
export type Msg =
  | [typeof PressedEnter]
  | [typeof ChangedDraft, string]
  | [typeof ReceivedMessages, Array<{ user: User; message?: Maybe<string> }>]
  | [typeof ClickedExit]

export const PressedEnter = "PressedEnter"
export const ChangedDraft = "ChangedDraft"
export const ReceivedMessages = "ReceivedMessages"
export const ClickedExit = "ClickedExit"
