> [!CAUTION]
> The current AIR 51 / Apple Silicon compatibility rewrite in this repository was produced entirely by GPT-5.4. Neither GPT-5.4 nor the original author is responsible for any damage or data loss that may result from using this tool.

> [!TIP]
> There is now an iOS YNAB Classic app modernizer patch located in my other repository [newkind/ynab-classic-ios-modernizer](https://github.com/newkind/ynab-classic-ios-modernizer) Please note that you have to supply your own **decrypted** IPA file for it to work.

# YNAB 4 Universal (Intel & Apple Silicon) Binary Converter for macOS

YNAB 4 originally shipped with an old Intel-era captive Adobe AIR runtime. That approach survived the 32-bit transition, but it still leaves the app dependent on Rosetta 2 on Apple Silicon Macs. As Apple continues moving away from Intel compatibility, that is not a stable long-term path for keeping YNAB 4 usable.

This repository rebuilds the final release of YNAB 4 for macOS (v4.3.855) around Adobe AIR `51.3.1.2` and produces a universal app bundle that runs natively on both Intel and Apple Silicon Macs. The rebuilt app uses AIR 51's universal launcher/runtime, restores a small compatibility helper that AIR still expects for captive launches, patches out AIR's obsolete privileged helper-install path, and replaces YNAB 4's legacy native extensions with universal shims so the resulting app is no longer tied to Intel-only AIR binaries. You still need a valid license key to use YNAB 4.

This shell script is not affiliated with YNAB in any way, and YNAB has not endorsed it. YNAB has [officially ended support](https://web.archive.org/web/20191008235951/https://www.youneedabudget.com/ynab-4-support-will-end-october-2019/) for YNAB 4. Do not contact them with support requests of any kind related to this shell script or to using YNAB 4 on modern macOS versions. You are on your own, and you use it at your own risk.

> [!NOTE]
> Disclaimer: Original credit for the YNAB 4 32-bit-to-64-bit conversion script goes to https://gitlab.com/bradleymiller/Y64/-/tree/master

## Usage

To run the script, do the following:

1. Make sure the Xcode Command Line Tools are installed (`xcode-select -p` should work).
2. If verified copies of `AdobeAIR.dmg` and `YNAB4_LiveCaptive_4.3.855.dmg` are not found in the repository root, the script will attempt to download them from the internet.
3. Press `Command (⌘) + Space`
4. Type `Terminal` and press Enter
5. Optionally make the installer executable:

   ```bash
   chmod +x install
   ```

6. Run:

   ```bash
   ./install
   ```

7. When the script is complete, drag the resulting app to `/Applications`

## How It Works

YNAB 4 is written in ActionScript and runs on top of Adobe AIR. The original app bundle includes an old captive AIR runtime and two legacy native extensions (`macutils` and `sparkle`) that were built for obsolete macOS targets.

The updated workflow:

1. Reuses verified local DMGs or downloads fresh copies of YNAB 4 and AIR `51.3.1.2`
2. Extracts the clean YNAB 4 app from the original DMG
3. Replaces the bundled AIR framework with the AIR `51.3.1.2` framework from `AdobeAIR.dmg`
4. Patches AIR 51's universal launcher back into captive-runtime mode
5. Restores the missing `A2712Enabler` helper as a no-op compatibility shim
6. Patches AIR 51's obsolete privileged helper-install code path so launching no longer prompts for an admin password
7. Rebuilds the two legacy native extensions as small universal Objective-C shims
8. Ad-hoc signs the rebuilt app to avoid stale nested signatures

## Limitations

- Will not work with App Store-purchased licenses unless you have received a separate license key. Refer to YNAB's [Mac App Store FAQ](https://web.archive.org/web/20170817002804/https://classic.youneedabudget.com/support/article/mac-app-store-faq).
- The `Check for Updates` function does not work. The Sparkle integration is intentionally stubbed.
- The script depends on `clang`, `curl`, `python3`, and `shasum`. `clang` is provided by the Xcode Command Line Tools.

## Other Methods

You may still be able to run older YNAB 4 builds through virtualization or compatibility layers, but this project exists specifically to avoid relying on Rosetta 2 for the macOS app.

## Legal Stuff

**IMPORTANT NOTE:** This shell script is not affiliated with YNAB in any way, and YNAB has not endorsed it. You Need a Budget and YNAB are registered trademarks of You Need a Budget LLC and/or one of its subsidiaries.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
