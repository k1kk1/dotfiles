import { Action, ActionPanel, Icon, List } from "@raycast/api";
import { useEffect, useState } from "react";
import { AlfredItem, iconFor, loadItems, runHerdr } from "./shared";

export default function HerdrResume() {
  const [items, setItems] = useState<AlfredItem[]>([]);
  const [error, setError] = useState<string>();
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    loadItems("resume")
      .then(setItems)
      .catch((reason: unknown) =>
        setError(reason instanceof Error ? reason.message : String(reason)),
      )
      .finally(() => setIsLoading(false));
  }, []);

  return (
    <List
      isLoading={isLoading}
      searchBarPlaceholder="Search Claude Code and Codex conversations"
    >
      {error ? (
        <List.EmptyView
          icon={Icon.ExclamationMark}
          title="Could not load conversations"
          description={error}
        />
      ) : null}
      {!error && !isLoading && items.length === 0 ? (
        <List.EmptyView title="No conversations recorded" />
      ) : null}
      {items.map((item, index) => {
        const id = item.arg?.replace(/^workspace:/, "");
        return (
          <List.Item
            key={`${item.arg ?? item.title}-${index}`}
            icon={iconFor(item, Icon.Message)}
            title={item.title}
            subtitle={item.subtitle}
            keywords={[item.match ?? ""]}
            actions={
              <ActionPanel>
                <Action
                  title="Resume in New Workspace"
                  icon={Icon.Window}
                  onAction={() =>
                    item.arg &&
                    runHerdr(["resume", item.arg], `Resuming ${item.title}`)
                  }
                />
                <Action
                  title="Resume in New Tab"
                  shortcut={{ modifiers: ["shift"], key: "enter" }}
                  icon={Icon.AppWindow}
                  onAction={() =>
                    id &&
                    runHerdr(
                      ["resume", `tab:${id}`],
                      `Resuming ${item.title} in a tab`,
                    )
                  }
                />
                <Action
                  title="Resume Beside Current Pane"
                  shortcut={{ modifiers: ["opt"], key: "enter" }}
                  icon={Icon.Sidebar}
                  onAction={() =>
                    id &&
                    runHerdr(
                      ["resume", `split:${id}`],
                      `Resuming ${item.title} beside the pane`,
                    )
                  }
                />
                {item.text?.copy ? (
                  <Action.CopyToClipboard
                    title="Copy Resume Command"
                    content={item.text.copy}
                  />
                ) : null}
              </ActionPanel>
            }
          />
        );
      })}
    </List>
  );
}
