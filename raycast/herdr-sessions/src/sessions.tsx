import { Action, ActionPanel, Icon, List } from "@raycast/api";
import { useEffect, useState } from "react";
import { AlfredItem, iconFor, loadItems, runHerdr } from "./shared";

export default function HerdrSessions() {
  const [items, setItems] = useState<AlfredItem[]>([]);
  const [error, setError] = useState<string>();
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    loadItems()
      .then(setItems)
      .catch((reason: unknown) =>
        setError(reason instanceof Error ? reason.message : String(reason)),
      )
      .finally(() => setIsLoading(false));
  }, []);

  return (
    <List isLoading={isLoading} searchBarPlaceholder="Search Herdr sessions">
      {error ? (
        <List.EmptyView
          icon={Icon.ExclamationMark}
          title="Could not load Herdr sessions"
          description={error}
        />
      ) : null}
      {!error && !isLoading && items.length === 0 ? (
        <List.EmptyView title="No Herdr sessions" />
      ) : null}
      {items.map((item, index) => (
        <List.Item
          key={`${item.arg ?? item.title}-${index}`}
          icon={iconFor(item, Icon.Terminal)}
          title={item.title}
          subtitle={item.subtitle}
          keywords={[item.match ?? ""]}
          actions={
            <ActionPanel>
              <Action
                title="Open Session"
                icon={Icon.Terminal}
                onAction={() =>
                  item.arg &&
                  runHerdr(["open", item.arg], `Opening ${item.title}`)
                }
              />
              {item.text?.copy ? (
                <Action.CopyToClipboard
                  title="Copy Attach Command"
                  content={item.text.copy}
                />
              ) : null}
              <Action
                title="Refresh"
                icon={Icon.ArrowClockwise}
                onAction={() => {
                  setIsLoading(true);
                  loadItems()
                    .then(setItems)
                    .catch((reason: unknown) => setError(String(reason)))
                    .finally(() => setIsLoading(false));
                }}
              />
            </ActionPanel>
          }
        />
      ))}
    </List>
  );
}
