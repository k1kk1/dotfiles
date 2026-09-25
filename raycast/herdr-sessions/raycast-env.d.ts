/// <reference types="@raycast/api">

/* 🚧 🚧 🚧
 * This file is auto-generated from the extension's manifest.
 * Do not modify manually. Instead, update the `package.json` file.
 * 🚧 🚧 🚧 */

/* eslint-disable @typescript-eslint/ban-types */

type ExtensionPreferences = {}

/** Preferences accessible in all the extension's commands */
declare type Preferences = ExtensionPreferences

declare namespace Preferences {
  /** Preferences accessible in the `cheatsheet` command */
  export type Cheatsheet = ExtensionPreferences & {}
  /** Preferences accessible in the `sessions` command */
  export type Sessions = ExtensionPreferences & {}
  /** Preferences accessible in the `resume` command */
  export type Resume = ExtensionPreferences & {}
}

declare namespace Arguments {
  /** Arguments passed to the `cheatsheet` command */
  export type Cheatsheet = {}
  /** Arguments passed to the `sessions` command */
  export type Sessions = {}
  /** Arguments passed to the `resume` command */
  export type Resume = {}
}

