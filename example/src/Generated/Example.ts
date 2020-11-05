import { Maybe, Result } from "./Basics/Basics"


/** To define what can happen.
 */
export type Msg =
  | [typeof PressedEnter]
  | [typeof ChangedDraft, string]
  | [typeof ReceivedMessages, Array<{ user: User; message: string }>]
  | [typeof ClickedExit]

export const PressedEnter = "PressedEnter"
export const ChangedDraft = "ChangedDraft"
export const ReceivedMessages = "ReceivedMessages"
export const ClickedExit = "ClickedExit"


/** To distinguish between users.
 */
export type User =
  | [typeof Regular, string, number]
  | [typeof Visitor, string]
  | [typeof Anonymous]

export const Regular = "Regular"
export const Visitor = "Visitor"
export const Anonymous = "Anonymous"
