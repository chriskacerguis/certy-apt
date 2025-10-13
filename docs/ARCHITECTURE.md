# Dynamic Package Generation - Visual Overview

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                      Package Build Process                       │
└─────────────────────────────────────────────────────────────────┘

     ┌──────────────┐
     │  Certy       │
     │  Binary      │◄──────┐
     └──────────────┘       │
            │               │
            │ --version     │ -h, --help
            │               │
            ▼               ▼
     ┌──────────────┐  ┌──────────────┐
     │  Version     │  │  Help Text   │
     │  Info        │  │  & Options   │
     └──────────────┘  └──────────────┘
            │               │
            │               │
            └───────┬───────┘
                    │
                    ▼
            ┌──────────────┐
            │  Man Page    │◄─────┐
            │  Generator   │      │
            └──────────────┘      │
                    │             │
                    │             │
     ┌──────────────┼─────────────┘
     │              │
     │              ▼
     │      ┌──────────────┐       ┌──────────────┐
     │      │  Dynamic     │       │  GitHub      │
     │      │  Man Page    │       │  README.md   │◄─────┐
     │      │  (.1.gz)     │       └──────────────┘      │
     │      └──────────────┘              │              │
     │              │                     │ curl         │
     │              │                     │              │
     │              │                     ▼              │
     │              │              ┌──────────────┐      │
     │              │              │  Features    │      │
     │              │              │  Extraction  │      │
     │              │              └──────────────┘      │
     │              │                     │              │
     │              │                     │              │
     │              └──────┬──────────────┘              │
     │                     │                             │
     │                     ▼                             │
     │              ┌──────────────┐              ┌─────────────┐
     │              │  Package     │              │  Cache      │
     │              │  Control     │              │  (1 hour)   │
     │              │  File        │              └─────────────┘
     │              └──────────────┘                     ▲
     │                     │                             │
     │                     │                             │
     └──────┬──────────────┘                             │
            │                                            │
            ▼                                            │
     ┌──────────────┐                                    │
     │  Complete    │                                    │
     │  .deb        │                                    │
     │  Package     │                                    │
     └──────────────┘                                    │
            │                                            │
            │                                            │
            ▼                                            │
     ┌──────────────┐                                    │
     │  APT         │                                    │
     │  Repository  │                                    │
     └──────────────┘                                    │
                                                         │
┌────────────────────────────────────────────────────────┘
│  Helper Script: get-certy-info.sh
│  ├── get_binary_version()
│  ├── get_binary_help()
│  ├── get_readme_content()
│  ├── extract_features_from_readme()
│  ├── cache_github_data()
│  └── generate_man_options_from_help()
└────────────────────────────────────────────────────────
```

## Information Flow

```
┌─────────────────┐
│  Source 1:      │
│  Certy Binary   │────────┐
└─────────────────┘        │
                           │
┌─────────────────┐        │    ┌─────────────────────┐
│  Source 2:      │        ├───►│  build-deb.sh       │
│  GitHub README  │────────┤    │  (Main Script)      │
└─────────────────┘        │    └─────────────────────┘
                           │              │
┌─────────────────┐        │              │
│  Source 3:      │        │              │
│  Static         │────────┘              │
│  Defaults       │                       │
└─────────────────┘                       │
     (Fallback)                           │
                                          ▼
                                ┌─────────────────────┐
                                │  Package Outputs:   │
                                ├─────────────────────┤
                                │  • Man page         │
                                │  • Control file     │
                                │  • Documentation    │
                                │  • .deb package     │
                                └─────────────────────┘
```

## Fallback Strategy

```
Primary Path:
  Binary/GitHub → Extract → Use ✓

Fallback Path:
  Fetch Failed → Static Defaults → Use ✓

Error Handling:
  ┌─ Try Binary Help ───┐
  │                     │
  ├─ Success? ──Yes──► Use Dynamic Content
  │                     
  └─ No? ──────────────► Use Static Content
                         (Still builds successfully)
```

## Data Flow Example

### OPTIONS Section Generation

```
1. Execute: certy -h
   Output:
   -install     Initialize CA
   -client      Generate client cert
   -ecdsa       Use ECDSA keys
   ...

2. Parse:
   Flag: -install
   Description: Initialize CA
   
   Flag: -client
   Description: Generate client cert

3. Generate Man Page:
   .SH OPTIONS
   .TP
   .B -install
   Initialize CA
   .TP
   .B -client
   Generate client cert
   ...

4. Result:
   User runs: man certy
   Sees current options from actual binary
```

## Cache Mechanism

```
Request for GitHub Data
        │
        ▼
  ┌─────────────────┐
  │ Check Cache     │
  └─────────────────┘
        │
        ├─ Exists & Fresh? ──Yes──► Return Cached Data
        │
        └─ No or Expired
              │
              ▼
        ┌─────────────────┐
        │ Fetch from      │
        │ GitHub API      │
        └─────────────────┘
              │
              ├─ Success? ──Yes──► Cache & Return
              │
              └─ Failed ──────────► Return Old Cache or Fallback
```

## Timeline Comparison

### Before (Manual Updates)

```
Day 1:  Certy adds new flag
Day 2:  Users get new binary
Day 3:  Issue: "New flag not documented!"
Day 4:  Maintainer manually updates man page
Day 5:  New package released
Day 6:  Users get updated docs
```

### After (Dynamic Updates)

```
Day 1:  Certy adds new flag
Day 2:  Users get new binary
        ↓ (automatic)
        Package build extracts new flag
        ↓ (automatic)
        Man page includes new flag
        ↓ (automatic)
        Complete documentation
```

## Component Interaction

```
┌──────────────────────────────────────────────────────┐
│  GitHub Actions Workflow                             │
│                                                      │
│  ┌────────────────────────────────────────────┐    │
│  │  1. Download Certy Binary                  │    │
│  └─────────────────┬──────────────────────────┘    │
│                    │                                │
│  ┌─────────────────▼──────────────────────────┐    │
│  │  2. Execute build-deb.sh                   │    │
│  │     ├─ Source get-certy-info.sh           │    │
│  │     ├─ Extract from binary                 │    │
│  │     ├─ Fetch from GitHub                   │    │
│  │     ├─ Generate man page                   │    │
│  │     └─ Build .deb package                  │    │
│  └─────────────────┬──────────────────────────┘    │
│                    │                                │
│  ┌─────────────────▼──────────────────────────┐    │
│  │  3. Update Repository Metadata             │    │
│  └─────────────────┬──────────────────────────┘    │
│                    │                                │
│  ┌─────────────────▼──────────────────────────┐    │
│  │  4. Deploy to GitHub Pages                 │    │
│  └────────────────────────────────────────────┘    │
│                                                      │
└──────────────────────────────────────────────────────┘
```

## File Dependencies

```
build-deb.sh
    │
    ├─ Requires: build/certy-${ARCH}
    ├─ Requires: debian/control.template
    ├─ Requires: debian/postinst
    ├─ Requires: debian/prerm
    ├─ Sources:  scripts/get-certy-info.sh (optional)
    │
    ├─ Generates: .deb package
    │   ├─ usr/bin/certy
    │   ├─ usr/share/man/man1/certy.1.gz
    │   ├─ usr/share/doc/certy/
    │   └─ DEBIAN/control
    │
    └─ Outputs:  build/certy_${VERSION}_${ARCH}.deb
```

## Success Indicators

### Build Success
```
✓ Binary found and executable
✓ Version extracted
✓ Help text extracted
✓ Features fetched (or fallback used)
✓ Man page generated
✓ Control file populated
✓ Package built
✓ Package validates (lintian)
```

### Runtime Success
```
✓ Package installs
✓ Binary works: certy --version
✓ Man page accessible: man certy
✓ Help shows: certy -h
✓ All flags documented
✓ Examples accurate
```

## Maintenance Points

```
Regular:
  • Monitor GitHub API rate limits
  • Check cache effectiveness
  • Verify fallbacks work

Occasional:
  • Update static defaults if major changes
  • Improve parsing if Certy format changes
  • Add new dynamic sources as needed

Rare:
  • Adjust cache TTL
  • Change GitHub repo URL
  • Modify template format
```
