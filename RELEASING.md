# PhotoTag.ai Lightroom Classic Plug-In Release Procedure

This repository is not deployed by a normal commit and push. The repository owner must package and publish each installable version manually through GitHub Releases. The PhotoTag.ai site automatically discovers the published latest release.

## Release contract

Every change intended for release must update `VERSION` in `Info.lua`. This includes Lua source, settings, UI, packaging, and documentation changes.

Use one new version for the complete change set. Do not increment once per file. Existing releases use three numeric components without a `v` prefix, such as `1.2.7`.

For a compatible fix or small feature, increment `revision`. Use a new `minor` or `major` version only when the owner intentionally chooses that scope.

The version must match in all three places:

1. `VERSION` in `Info.lua`, represented as `major`, `minor`, and `revision`.
2. The Git tag, such as `1.2.8`.
3. The GitHub release title, using `PhotoTag.ai Lightroom Classic Plug-In 1.2.8`.

The uploaded asset name is always exactly `phototagai.lrplugin.zip`.

## Before commit and push

1. Confirm that `Info.lua` contains a version that has not already been released.
2. Review the full diff and confirm that no token, local setting, catalog, preview, test photo, credential, or private data is present.
3. Run the repository's available syntax checks.
4. When Lightroom Classic is available, load the development plug-in and exercise every changed flow. Do not claim Lightroom runtime verification when only static checks were run.
5. Record the user-visible changes for the GitHub release notes.

Committing and pushing require explicit owner authorization. They do not package or publish the plug-in.

## Manual packaging after commit and push

Run the packaging command from the repository root after the intended release commit is pushed:

```bash
git archive --format=zip --prefix=phototagai.lrplugin/ --output=../phototagai.lrplugin.zip HEAD
```

This creates the required top-level `phototagai.lrplugin/` folder and packages every tracked file from the release commit. It excludes `.git`, ignored local agent instructions, local settings, and untracked files.

Do not use a ZIP that contains loose plug-in files at the archive root. Do not create a double-nested path such as `phototagai.lrplugin/phototagai.lrplugin/`.

Inspect the archive before uploading it:

```bash
unzip -l ../phototagai.lrplugin.zip
```

The archive must contain these paths under one top-level folder:

- `phototagai.lrplugin/Info.lua`
- `phototagai.lrplugin/MetadataGenerator.lua`
- `phototagai.lrplugin/PluginInfoProvider.lua`
- `phototagai.lrplugin/dkjson.lua`
- `phototagai.lrplugin/README.md`
- `phototagai.lrplugin/RELEASING.md`

The archive must not contain:

- `.git/`
- `AGENTS.md`
- `__MACOSX/`
- `.DS_Store`
- Tokens, credentials, catalogs, previews, test photos, local settings, or unrelated files

Delete or replace any stale `phototagai.lrplugin.zip` before packaging so the uploaded file is unquestionably built from the intended commit.

## Manual GitHub release

Use the [phototagai.lrplugin releases page](https://github.com/joincodeconda/phototagai.lrplugin/releases) after the commit is pushed.

1. Select "Draft a new release".
2. Create or select a tag that exactly matches `Info.lua`, such as `1.2.8`. Do not add a `v` prefix.
3. Target the pushed release commit on the primary branch.
4. Set the title to `PhotoTag.ai Lightroom Classic Plug-In 1.2.8`, substituting the actual version.
5. Add concise release notes that describe the user-visible behavior and important fixes.
6. Upload the manually created asset with the exact filename `phototagai.lrplugin.zip`.
7. Leave the release as a normal production release unless it is intentionally a prerelease.
8. Set it as the latest release and publish it.

GitHub documents the release form and binary asset upload process in [Managing releases in a repository](https://docs.github.com/en/repositories/releasing-projects-on-github/managing-releases-in-a-repository).

## Why the exact names matter

The PhotoTag.ai site requests GitHub's latest release metadata, reads its tag, and constructs this download URL:

```text
https://github.com/joincodeconda/phototagai.lrplugin/releases/download/VERSION/phototagai.lrplugin.zip
```

Publishing the release as latest makes it available to the site automatically. No separate PhotoTag.ai site code change is required when the tag and asset follow this convention.

## Post-release verification

1. Open the published GitHub release and confirm that `phototagai.lrplugin.zip` downloads successfully.
2. Confirm that the release is marked latest and that its tag matches `Info.lua`.
3. Open the PhotoTag.ai Lightroom plug-in page and confirm that its download action retrieves the new asset.
4. Unzip the downloaded asset and confirm that it produces one `phototagai.lrplugin` folder with the expected files.
5. When Lightroom Classic is available, install that exact downloaded package and verify the changed behavior.
6. Keep the previous GitHub release and asset available for rollback.

If the new release is broken, mark the previous known-good release as latest so the site returns to it. Then publish the correction as a new higher version. Do not silently replace a published version with different code.

## Required agent handoff

Any agent that changes this repository must:

1. Update `VERSION` in `Info.lua` as part of the same change set.
2. State whether Lightroom Classic runtime verification was completed.
3. End the final response with the exact heading `MANUAL ACTION REQUIRED!`.
4. Under that heading, tell the owner that after commit and push they must create `phototagai.lrplugin.zip`, publish the matching GitHub release, and verify automatic pickup by the PhotoTag.ai site.

An agent must not claim that commit and push deploy this plug-in. An agent must not create a commit, push, tag, ZIP, or GitHub release unless the owner explicitly requests that exact action.
