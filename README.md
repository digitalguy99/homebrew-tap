# digitalguy99/tap

Homebrew casks by digitalguy99.

## Rakuten Link (menu bar only)

```sh
brew install --cask digitalguy99/tap/rakuten-link
```

This installs [Rakuten Link](https://network.mobile.rakuten.co.jp/service/rakuten-link/) so it runs from the menu bar only, with no Dock icon and no window at login.

How it works:

1. Downloads the official `RakutenLink.zip` from Rakuten's servers. Nothing modified is hosted here.
2. Checks that the app is signed by Rakuten Group, Inc. (`87CT3T3CK2`) and notarized by Apple, and refuses to continue otherwise.
3. Sets `LSUIElement` (no Dock icon), uses the bundle ID `jp.co.rakuten.link.tray`, and re-signs the app for your Mac only.
4. Adds a login agent that starts Rakuten Link and closes its startup window.

Notes:

- **Unofficial.** Not affiliated with, endorsed by, or supported by Rakuten.
- The patched app can't update itself. Run `brew upgrade --cask rakuten-link` instead.
- macOS may ask again for microphone and camera access after each upgrade.
- Rakuten Link is Intel-only, so Apple silicon Macs need Rosetta 2.

Uninstall with `brew uninstall --cask rakuten-link`. Add `--zap` to also remove its data.
