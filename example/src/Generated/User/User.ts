import { Maybe, Result } from "../Basics/Basics"


/** To distinguish between users.
 */
export type User =
  | [typeof Regular, string, number]
  | [typeof Visitor, string]
  | [typeof Anonymous]

export const Regular = "Regular"
export const Visitor = "Visitor"
export const Anonymous = "Anonymous"
