# PhotoTag.ai Metadata Generator for Lightroom Classic

The **PhotoTag.ai Metadata Generator** is a Lightroom Classic plug-in that automates the generation of metadata (title, description, keywords, and optional alt text) for photos in your catalog using the [PhotoTag.ai API](https://www.phototag.ai). This tool makes it easy to add AI-generated, context-aware metadata to your images, streamlining the process of organizing and optimizing your photo collection.

## Features

- **Automatic Metadata Generation**: Generate **title**, **description**, and **keywords** for your photos automatically with AI.
- **Optional Alt Text**: Fill Lightroom's **Alt Text (Accessibility)** field from the AI-generated caption (requires Lightroom Classic 13.2 or later).
- **Multi-Language Support**: Generate metadata in multiple languages, including English, Spanish, French, and more.
- **Custom Keyword Options**: Customize the number of keywords, required and excluded keywords, and context-specific keywords for more accurate results.
- **Batch Processing**: Process multiple photos in a single run, with progress tracking.
- **Integration with Lightroom**: The generated metadata is written directly to Lightroom's native fields (title, caption, keywords, and alt text when enabled).

## Installation

1. **Download the Plugin**: Clone or download this repository to your local machine.
2. **Add the Plugin to Lightroom**:
   - Open Lightroom Classic.
   - Go to `File` > `Plug-in Manager`.
   - Click `Add`, then navigate to the folder where you saved the plug-in, and click `Add Plug-in`.
3. **Configure API Settings**:
   - In the Lightroom Plug-in Manager, configure your **PhotoTag.ai API token**.
   - Customize your settings, such as language preferences, keyword limits, and context, to suit your needs.

## How to Use

1. **Select Photos**: Select the photos you want to generate metadata for in Lightroom.
2. **Run the Plugin**: Go to `Library` > `Plug-in Extras` > `Generate Metadata for Selected Photos`.
3. **Configure Options**: In the dialog, scroll to **Accessibility Settings** and check **Fill alt text from generated caption** if you want alt text (Lightroom Classic 13.2+ only).
4. **Progress Bar**: The plug-in will display a progress bar while it processes the selected photos.
5. **Review and Edit Metadata**: After processing, review title, caption, keywords, and alt text as needed.

### Alt Text (Accessibility)

- Alt text is written to the **Alt Text (Accessibility)** metadata field, not the Caption field.
- Requires **Lightroom Classic 13.2 or later** (check **Help > System Info**).
- If you do not see the field, open the **Metadata** panel in the Library module and click **Customize** at the bottom to add **Alt Text (Accessibility)** to your view.
- The option is off by default. When enabled on an unsupported Lightroom version, the plug-in will warn you before processing starts.

## Configuration

Settings in the run dialog (Library > Plug-in Extras):

- **Fill alt text from generated caption**: Writes AI caption (or title fallback) to Alt Text (Accessibility).
- **Preserve existing keywords**: Adds new keywords without removing yours.
- **Disable title and caption generation**: Leaves existing title/caption unchanged.
- Language, keyword limits, custom context, and more.

Plug-in Manager settings:

- **API Token**: Your PhotoTag.ai API key.

## Requirements

- Adobe Lightroom Classic (version 5.0 or higher for title, caption, and keywords)
- Adobe Lightroom Classic **13.2 or later** for alt text (Accessibility) support
- A PhotoTag.ai API key (available from [PhotoTag.ai](https://www.phototag.ai/api))
- An active internet connection (for PhotoTag.ai API)

## Release deployment

A commit and push do not publish an installable Lightroom plug-in release.

1. Update the `VERSION` value in `Info.lua` when the release changes user-visible plug-in behavior.
2. Load the reviewed plug-in directory in a supported Lightroom Classic version and verify installation, settings persistence, metadata generation, batch handling, and relevant version-specific behavior.
3. Package the `.lrplugin` directory through the established release channel without local settings, tokens, catalogs, previews, or test photos.
4. Publish the package and release notes through the approved distribution location, then install that exact package on a clean test setup.
5. Retain the prior package so users can roll back if installation or runtime verification fails.
