import {
  Action,
  ActionPanel,
  closeMainWindow,
  Color,
  getApplications,
  Icon,
  Keyboard,
  List,
  open,
  showInFinder,
  showToast,
  Toast,
} from "@raycast/api";
import { readFile } from "node:fs/promises";
import { homedir } from "node:os";
import { join } from "node:path";
import { useCallback, useEffect, useState } from "react";

/* Raycast's title-case rule targets English; Polish action titles use sentence case. */
/* eslint-disable @raycast/prefer-title-case */

const CATALOG_PATH = join(homedir(), "Library", "Application Support", "CCOpener", "projects.json");
const CCOPENER_BUNDLE_ID = "com.ccopener.app";

type Project = {
  name: string;
  path: string;
  isFavorite: boolean;
};

type ProjectCatalog = {
  schemaVersion: number;
  projects: Project[];
};

export default function Command() {
  const [projects, setProjects] = useState<Project[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string>();

  const reload = useCallback(async () => {
    setIsLoading(true);
    setError(undefined);

    try {
      const catalog = await loadCatalog();
      setProjects(catalog.projects);
    } catch (loadError) {
      setProjects([]);
      setError(errorMessage(loadError));
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    void reload();
  }, [reload]);

  const favorites = projects.filter((project) => project.isFavorite);
  const otherProjects = projects.filter((project) => !project.isFavorite);

  return (
    <List isLoading={isLoading} searchBarPlaceholder="Szukaj projektu po nazwie lub ścieżce…">
      {!isLoading && projects.length === 0 ? (
        <List.EmptyView
          icon={Icon.Terminal}
          title={error ? "Nie udało się wczytać projektów" : "Brak projektów"}
          description={error ?? "Dodaj projekty w CCOpener, a następnie odśwież tę listę."}
          actions={
            <ActionPanel>
              <Action title="Otwórz CCOpener" icon={Icon.AppWindow} onAction={openCCOpener} />
              <Action
                title="Odśwież"
                icon={Icon.ArrowClockwise}
                shortcut={Keyboard.Shortcut.Common.Refresh}
                onAction={reload}
              />
            </ActionPanel>
          }
        />
      ) : (
        <>
          {favorites.length > 0 ? (
            <List.Section title="Ulubione">
              {favorites.map((project) => (
                <ProjectItem key={project.path} project={project} onReload={reload} />
              ))}
            </List.Section>
          ) : null}
          {otherProjects.length > 0 ? (
            <List.Section title={favorites.length > 0 ? "Projekty" : undefined}>
              {otherProjects.map((project) => (
                <ProjectItem key={project.path} project={project} onReload={reload} />
              ))}
            </List.Section>
          ) : null}
        </>
      )}
    </List>
  );
}

function ProjectItem({ project, onReload }: { project: Project; onReload: () => Promise<void> }) {
  return (
    <List.Item
      title={project.name}
      subtitle={project.path}
      keywords={[project.path]}
      icon={{ source: Icon.Folder, tintColor: project.isFavorite ? Color.Yellow : Color.SecondaryText }}
      accessories={project.isFavorite ? [{ icon: { source: Icon.Star, tintColor: Color.Yellow } }] : undefined}
      actions={
        <ActionPanel>
          <ActionPanel.Section>
            <Action title="Uruchom Claude Code" icon={Icon.Terminal} onAction={() => launchProject(project)} />
          </ActionPanel.Section>
          <ActionPanel.Section>
            <Action
              title="Pokaż w Finderze"
              icon={Icon.Finder}
              shortcut={{ modifiers: ["cmd", "shift"], key: "f" }}
              onAction={() => showInFinder(project.path)}
            />
            <Action.CopyToClipboard title="Kopiuj ścieżkę" content={project.path} />
          </ActionPanel.Section>
          <ActionPanel.Section>
            <Action
              title="Odśwież"
              icon={Icon.ArrowClockwise}
              shortcut={Keyboard.Shortcut.Common.Refresh}
              onAction={onReload}
            />
            <Action title="Otwórz CCOpener" icon={Icon.AppWindow} onAction={openCCOpener} />
          </ActionPanel.Section>
        </ActionPanel>
      }
    />
  );
}

async function loadCatalog(): Promise<ProjectCatalog> {
  const contents = await readFile(CATALOG_PATH, "utf8");
  const catalog: unknown = JSON.parse(contents);

  if (!isProjectCatalog(catalog)) {
    throw new Error("Katalog projektów ma nieobsługiwany format. Uruchom ponownie najnowszą wersję CCOpener.");
  }

  return catalog;
}

function isProjectCatalog(value: unknown): value is ProjectCatalog {
  if (!value || typeof value !== "object") return false;

  const catalog = value as Partial<ProjectCatalog>;
  return (
    catalog.schemaVersion === 1 &&
    Array.isArray(catalog.projects) &&
    catalog.projects.every(
      (project) =>
        typeof project?.name === "string" &&
        typeof project.path === "string" &&
        typeof project.isFavorite === "boolean",
    )
  );
}

async function launchProject(project: Project) {
  const toast = await showToast({
    style: Toast.Style.Animated,
    title: `Uruchamiam ${project.name}`,
  });

  try {
    const url = `ccopener://launch?path=${encodeURIComponent(project.path)}`;
    await open(url);
    toast.style = Toast.Style.Success;
    toast.title = `Uruchomiono ${project.name}`;
    await closeMainWindow();
  } catch (launchError) {
    toast.style = Toast.Style.Failure;
    toast.title = "Nie udało się uruchomić projektu";
    toast.message = errorMessage(launchError);
  }
}

async function openCCOpener() {
  try {
    const applications = await getApplications();
    const ccopener = applications.find((application) => application.bundleId === CCOPENER_BUNDLE_ID);

    if (!ccopener) {
      throw new Error("Zbuduj CCOpener, przenieś aplikację do /Applications i uruchom ją przynajmniej raz.");
    }

    await open(ccopener.path);
  } catch (openError) {
    await showToast({
      style: Toast.Style.Failure,
      title: "Nie znaleziono CCOpener",
      message: errorMessage(openError),
    });
  }
}

function errorMessage(error: unknown): string {
  if (error instanceof Error) {
    if ((error as NodeJS.ErrnoException).code === "ENOENT") {
      return "Uruchom CCOpener przynajmniej raz, aby utworzyć katalog projektów.";
    }
    return error.message;
  }

  return String(error);
}
