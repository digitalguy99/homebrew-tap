cask "rakuten-link" do
  version "2.1.0"
  sha256 :no_check

  url "https://desktop.link.link/app/RakutenLink.zip"
  name "Rakuten Link (menu bar only)"
  desc "Rakuten Mobile calling and messaging app, patched to run from the menu bar"
  homepage "https://network.mobile.rakuten.co.jp/service/rakuten-link/"

  livecheck do
    url "https://desktop.link.link/app/latest-mac.yml"
    strategy :electron_builder
  end

  depends_on :macos

  app "Rakuten Link.app"

  # Patch the staged copy before it is moved into place. The official build is
  # verified first, so only Rakuten's own notarized app is ever modified.
  preflight_steps do
    run "/usr/bin/codesign",
        args: [
          "--verify", "--deep", "--strict",
          "-R=anchor apple generic and certificate leaf[subject.OU] = \"87CT3T3CK2\"",
          "{{staged_path}}/Rakuten Link.app"
        ]

    # LSUIElement hides the Dock icon; a separate bundle ID keeps it apart from
    # an official install. Editing Info.plist breaks Rakuten's signature, so the
    # app is re-signed ad hoc for this Mac only.
    run "/usr/libexec/PlistBuddy",
        args: [
          "-c", "Set :CFBundleIdentifier jp.co.rakuten.link.tray",
          "-c", "Add :LSUIElement bool true",
          "{{staged_path}}/Rakuten Link.app/Contents/Info.plist"
        ]
    run "/usr/bin/codesign",
        args: [
          "--force", "--deep", "--sign", "-", "--preserve-metadata=entitlements",
          "{{staged_path}}/Rakuten Link.app"
        ]
    run "/usr/bin/xattr", args: ["-dr", "com.apple.quarantine", "{{staged_path}}/Rakuten Link.app"]
  end

  # LSUIElement only removes the Dock icon; the app still opens its main window
  # at launch. This login agent launches it and closes that window, leaving just
  # the menu bar icon.
  postflight_steps do
    write_file "rakuten-link-tray.sh", <<~SH
      #!/bin/zsh
      set -euo pipefail

      open -a "{{appdir}}/Rakuten Link.app"

      # Wait for the process to register with System Events.
      for i in $(seq 1 40); do
        if osascript -e 'tell application "System Events" to get name of process "Rakuten Link"' > /dev/null 2>&1; then
          break
        fi
        sleep 0.5
      done

      # Keep closing its window for a while: on a cold boot it can appear late.
      for i in $(seq 1 30); do
        osascript -e 'tell application "System Events" to tell process "Rakuten Link" to if (count windows) > 0 then click button 1 of window 1' > /dev/null 2>&1 || true
        sleep 1
      done
    SH
    set_permissions "rakuten-link-tray.sh", "0755"

    mkdir_p "Library/LaunchAgents", base: :home
    write_file "Library/LaunchAgents/io.github.digitalguy99.rakuten-link-tray.plist", <<~XML, base: :home
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
        <key>Label</key>
        <string>io.github.digitalguy99.rakuten-link-tray</string>
        <key>ProgramArguments</key>
        <array>
          <string>{{staged_path}}/rakuten-link-tray.sh</string>
        </array>
        <key>RunAtLoad</key>
        <true/>
      </dict>
      </plist>
    XML
  end

  uninstall_postflight_steps do
    remove "Library/LaunchAgents/io.github.digitalguy99.rakuten-link-tray.plist", base: :home
  end

  uninstall launchctl: "io.github.digitalguy99.rakuten-link-tray",
            quit:      "jp.co.rakuten.link.tray"

  zap trash: [
    "~/Library/Application Support/Caches/rakuten-updater",
    "~/Library/Application Support/Rakuten Link",
    "~/Library/Caches/jp.co.rakuten.link.tray",
    "~/Library/Caches/jp.co.rakuten.link.tray.ShipIt",
    "~/Library/HTTPStorages/jp.co.rakuten.link.tray",
    "~/Library/Logs/Rakuten Link",
    "~/Library/Preferences/jp.co.rakuten.link.tray.plist",
  ]

  caveats do
    requires_rosetta
    <<~EOS
      This is an unofficial, locally patched build. It is not affiliated with or
      supported by Rakuten. The app is downloaded from Rakuten's servers and only
      modified on your Mac after its official signature is verified.

      Rakuten Link starts in the menu bar at your next login. To start it now:
        launchctl load ~/Library/LaunchAgents/io.github.digitalguy99.rakuten-link-tray.plist

      The patched app cannot update itself. Use `brew upgrade --cask rakuten-link`.
      macOS may ask again for microphone and camera access after each upgrade, and
      may ask you to allow Accessibility access so the startup window can be closed.
    EOS
  end
end
