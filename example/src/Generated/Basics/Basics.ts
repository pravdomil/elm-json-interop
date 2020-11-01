export type Maybe<a> = a | null

export type Result<error, value> = [typeof Ok, value] | [typeof Err, error]

export const Ok = "Ok"
export const Err = "Err"
