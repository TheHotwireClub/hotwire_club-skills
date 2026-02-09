# Hotwire Club Skills

Claude skills for building modern web applications with [Hotwire](https://hotwired.dev/) (Turbo and Stimulus).

These skills are extracted from the [Hotwire Club](https://hotwire.club/) knowledge base and organized into 6 topic-based skills covering common patterns and best practices.

## Available Skills

### 1. User Experience & Feedback (`hwc-ux-feedback`)
Implement loading states, progress indicators, optimistic UI, and smooth transitions with Hotwire. Use this skill when building responsive feedback for user actions.

**Topics**: Turbo Drive, Turbo Frames, loading spinners, progress bars, optimistic UI, page transitions

### 2. Forms & Validation (`hwc-forms-validation`)
Handle form submissions, inline editing, real-time validation, and typeahead with Hotwire. Use this skill when building interactive forms.

**Topics**: Turbo Frames, inline editing, modals, validation, typeahead search, external form controls

### 3. Navigation & Content Display (`hwc-navigation-content`)
Build pagination, lazy loading, search, filtering, and tabbed navigation with Hotwire. Use this skill when organizing and displaying content.

**Topics**: Turbo Drive, Turbo Frames, pagination, lazy loading, tabs, scroll position, cache lifecycle

### 4. Real-Time & Streaming (`hwc-realtime-streaming`)
Implement WebSocket updates, live data, custom stream actions, and state synchronization with Hotwire. Use this skill when building real-time features.

**Topics**: Turbo Streams, WebSockets, custom stream actions, live updates, animations

### 5. Media & Rich Content (`hwc-media-content`)
Handle images, video, audio, file uploads, and playback tracking with Hotwire. Use this skill when integrating media and third-party libraries.

**Topics**: Stimulus, image loading, video/audio playback, file uploads, third-party integrations

### 6. Stimulus Fundamentals (`hwc-stimulus-fundamentals`)
Master Stimulus controller patterns including lifecycle hooks, value callbacks, outlets, targets, and events. Use this skill when building Stimulus controllers.

**Topics**: Stimulus controllers, lifecycle, values, targets, outlets, events, Web APIs

## Installation

### Using `npx skills` (Recommended)

The easiest way to install these skills is using the [Vercel Skills CLI](https://github.com/vercel-labs/skills):

```bash
# Install all skills to Claude Code
npx skills add TheHotwireClub/hotwire_club-skills -a claude-code

# List available skills first
npx skills add TheHotwireClub/hotwire_club-skills --list

# Install specific skills only
npx skills add TheHotwireClub/hotwire_club-skills --skill hwc-ux-feedback --skill hwc-forms-validation

# Install to multiple agents (Claude Code, Cursor, etc.)
npx skills add TheHotwireClub/hotwire_club-skills -a claude-code -a cursor
```

#### Managing Installed Skills

```bash
# List all installed skills
npx skills list

# List skills for a specific agent
npx skills ls -a claude-code

# Remove a skill
npx skills remove hwc-ux-feedback

# Remove from specific agent only
npx skills remove --agent claude-code hwc-ux-feedback
```

### Manual Installation (Claude Desktop)

1. Clone or download this repository to your local machine
2. Copy or symlink the skill directories from `skills/` to your Claude skills directory:
   - **macOS**: `~/.claude/skills/`
   - **Windows**: `%USERPROFILE%\.claude\skills\`
   - **Linux**: `~/.claude/skills/`

   Each skill is a directory containing `SKILL.md` and a `references/` folder:
   ```bash
   # Example: symlink all skills
   ln -s /path/to/hotwire_club-skills/skills/hwc-* ~/.claude/skills/
   ```

3. Restart Claude Desktop

### For Cursor or Other Editors

Copy the desired skill directories from `skills/` to your editor's skills directory. Each skill directory contains a `SKILL.md` file and a `references/` folder with full article content. Refer to your editor's documentation for the correct location.

## Directory Structure

```
hotwire_club-skills/
├── README.md                       # This file
├── skills/                         # Claude skill directories
│   ├── hwc-ux-feedback/
│   │   ├── SKILL.md                # Skill definition file
│   │   └── references/             # Full articles for this skill
│   ├── hwc-forms-validation/
│   │   ├── SKILL.md
│   │   └── references/
│   ├── hwc-navigation-content/
│   │   ├── SKILL.md
│   │   └── references/
│   ├── hwc-realtime-streaming/
│   │   ├── SKILL.md
│   │   └── references/
│   ├── hwc-media-content/
│   │   ├── SKILL.md
│   │   └── references/
│   └── hwc-stimulus-fundamentals/
│       ├── SKILL.md
│       └── references/
├── scripts/
│   └── sync-references.rb          # Script to sync articles from corpus
└── config/
    └── supertopic-mapping.yml      # Article-to-skill mapping
```

## Usage

Once installed, you can invoke these skills in Claude by:

1. **Referencing them in your prompts**: "Using the hwc-ux-feedback skill, help me implement a loading spinner"
2. **Letting Claude detect them**: Claude will automatically use relevant skills based on your question
3. **Browsing in the skills panel**: View available skills and their descriptions in Claude Desktop

## Updating

To update the skills with the latest articles from the Hotwire Club corpus:

```bash
cd hotwire_club-skills
ruby scripts/sync-references.rb
```

This will:
- Copy the latest articles from `../hotwire_club-mcp/corpus/` to each skill's `references/` directory
- Update the INDEX.md files for each skill
- Preserve existing SKILL.md files (you'll need to manually update them if needed)

## About Hotwire Club

The [Hotwire Club](https://hotwire.club/) is a comprehensive knowledge base and community for developers building modern web applications with Hotwire. These skills are based on 45+ tutorial articles covering real-world patterns and best practices.

Visit [hotwire.club](https://hotwire.club/) to:
- Access the full knowledge base
- Join the community
- Get support for your Hotwire projects

## License

These skills are provided for educational purposes. Original content is from [Hotwire Club](https://hotwire.club/) and subject to their licensing terms.

## Contributing

If you find issues or have suggestions for improving these skills, please open an issue or submit a pull request.
