import { closeMainWindow, showToast, Toast } from "@raycast/api";
import type { Image } from "@raycast/api";
import { execFile } from "node:child_process";
import { promisify } from "node:util";

const execFileAsync = promisify(execFile);

export const herdrSessions =
  "/Users/kikki/src/herdr-plugins/herdr-sessions/target/release/herdr-sessions";

export type AlfredItem = {
  title: string;
  subtitle?: string;
  arg?: string;
  match?: string;
  valid?: boolean;
  text?: { copy?: string };
  icon?: { type?: string; path?: string };
};

type AlfredResult = { items?: AlfredItem[] };

export async function loadItems(mode?: "resume"): Promise<AlfredItem[]> {
  const args = mode === "resume" ? ["alfred", "resume"] : ["alfred"];
  const { stdout } = await execFileAsync(herdrSessions, args, {
    env: process.env,
  });
  const result = JSON.parse(stdout) as AlfredResult;
  return result.items ?? [];
}

export async function runHerdr(args: string[], message: string): Promise<void> {
  await closeMainWindow();
  try {
    await execFileAsync(herdrSessions, args, { env: process.env });
    await showToast({ style: Toast.Style.Success, title: message });
  } catch (error) {
    await showToast({
      style: Toast.Style.Failure,
      title: "Herdr command failed",
      message: error instanceof Error ? error.message : String(error),
    });
  }
}

export function iconFor(
  item: AlfredItem,
  fallback: Image.ImageLike,
): Image.ImageLike {
  return item.icon?.type === "fileicon" && item.icon.path
    ? { fileIcon: item.icon.path }
    : fallback;
}
