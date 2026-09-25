import { closeMainWindow, showHUD } from "@raycast/api";
import { execFile } from "node:child_process";
import { promisify } from "node:util";

const execFileAsync = promisify(execFile);
const cheatsheet = "/Users/kikki/src/dotfiles/docs/cheatsheet.html";

export default async function openCheatSheet() {
  await closeMainWindow();
  await execFileAsync("/usr/bin/open", [cheatsheet]);
  await showHUD("Opened CheetSheet");
}
