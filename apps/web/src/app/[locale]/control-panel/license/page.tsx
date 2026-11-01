import {
  SettingsPage,
  SettingsPageContent,
  SettingsPageHeader,
  SettingsPageTitle,
} from "@/components/settings-layout";

/** Replaces the commercial activation screen in the community fork (2026-11-01). */
export default function SourcePage() {
  return (
    <SettingsPage>
      <SettingsPageHeader>
        <SettingsPageTitle>Community fork · AGPLv3</SettingsPageTitle>
      </SettingsPageHeader>
      <SettingsPageContent>
        <div className="space-y-4">
          <p>
            This self-hosted version has no commercial license checks or account
            and space seat limits.
          </p>
          <p>
            Based on Rallly by Luke Vella and contributors. Modified on
            2026-11-01. The original copyright notices and AGPLv3 license remain
            in effect.
          </p>
          <p>
            <a className="text-link" href="/source/rallly-current.tar.gz">
              Download this installation’s corresponding source
            </a>
          </p>
          <p>
            <a
              className="text-link"
              href="https://github.com/marek-somm/rallly-selfhosted"
            >
              Fork source and modification history on GitHub
            </a>
          </p>
          <p>
            <a className="text-link" href="https://github.com/lukevella/rallly">
              Original Rallly project
            </a>
          </p>
        </div>
      </SettingsPageContent>
    </SettingsPage>
  );
}
