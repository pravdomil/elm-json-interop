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


/**  */
export type ExampleBool = boolean


/**  */
export type ExampleInt = number


/**  */
export type ExampleFloat = number


/**  */
export type ExampleString = string


/**  */
export type ExampleMaybe = Maybe<string>


/**  */
export type ExampleList = Array<string>


/**  */
export type ExampleRecord = { a: string; b?: Maybe<string> }


/**  */
export type ExampleChar = string


/**  */
export type ExampleTuple = [string, string, string]


/**  */
export type ExampleResult = Result<string, string>


/**  */
export type ExampleSet = Array<string>


/**  */
export type ExampleDict = Record<string, string>
