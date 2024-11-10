# Choir: Harmonic Intelligence Platform

VERSION harmonic_system:
invariants: {
"Wave resonance",
"Energy conservation",
"Pattern emergence"
}
assumptions: {
"Apple ecosystem excellence",
"Swift implementation",
"Natural harmonics"
}
docs_version: "0.3.0"  # Post-alignment vision, Nov 2024
# ChoirChat UI Specification

VERSION choir_ui_system:
invariants: {
"Visual hierarchy",
"Interaction consistency",
"State reflection",
"Responsive adaptation"
}
assumptions: {
"Mobile-first design",
"Desktop enhancement",
"Theme consistency"
}
docs_version: "0.2.1"

## Layout Structure

```typescript
TYPE LayoutStructure = {
  // Base container (mobile-first)
  container: {
    default: "flex flex-col h-screen bg-gray-900",
    withPanel: "h-[calc(100vh-env(safe-area-inset-bottom))]", // iOS safe area
    desktop: "flex h-screen bg-gray-900" // Side-by-side on desktop
  },

  // Message thread view
  messageThread: {
    container: "flex-1 flex flex-col overflow-hidden",
    header: "px-4 py-3 border-b border-gray-800 flex items-center",
    content: "flex-1 overflow-y-auto",
    input: "border-t border-gray-800 p-4 pb-safe", // iOS safe area padding
    desktop: {
      container: "flex-1 flex flex-col",
      sidePanel: "w-80 border-l border-gray-800" // Desktop side panel
    }
  },

  // Response visualization
  responseView: {
    // Mobile: Bottom sheet with tabs
    mobile: {
      tabs: {
        container: "border-t border-gray-800 bg-gray-900",
        scroll: "flex overflow-x-auto hide-scrollbar",
        tab: {
          base: "px-4 py-2 whitespace-nowrap",
          active: "border-b-2 border-cyan-500 text-cyan-500",
          inactive: "text-gray-400"
        }
      },
      sheet: {
        overlay: "fixed inset-0 bg-black/50 z-40",
        container: {
          base: "fixed inset-x-0 bottom-0 z-50 bg-gray-900 rounded-t-xl",
          expanded: "h-[85vh]",
          collapsed: "h-[50vh]"
        },
        handle: "w-12 h-1 bg-gray-600 rounded-full mx-auto my-3",
        content: "px-4 overflow-y-auto h-full pb-safe"
      }
    },
    // Desktop: Side panel with fixed tabs
    desktop: {
      container: "w-80 border-l border-gray-800 flex flex-col",
      tabs: {
        container: "flex border-b border-gray-800",
        tab: {
          base: "flex-1 px-4 py-2 text-center",
          active: "bg-gray-800 text-cyan-500",
          inactive: "text-gray-400 hover:bg-gray-800/50"
        }
      },
      content: "flex-1 overflow-y-auto p-4"
    }
  }
}
```

## Step Visualization

```typescript
TYPE StepDisplay = {
  // Common step styling
  step: {
    action: {
      icon: "→",
      label: "Action",
      color: "cyan-500"
    },
    experience: {
      icon: "○",
      label: "Experience",
      color: "blue-500"
    },
    intention: {
      icon: "◇",
      label: "Intention",
      color: "purple-500"
    },
    observation: {
      icon: "□",
      label: "Observation",
      color: "green-500"
    },
    update: {
      icon: "△",
      label: "Update",
      color: "yellow-500"
    }
  },

  // Content display variants
  content: {
    mobile: {
      container: "space-y-4 px-4",
      header: "text-sm font-medium text-gray-400",
      body: "prose dark:prose-invert"
    },
    desktop: {
      container: "space-y-6",
      header: "text-base font-medium text-gray-300",
      body: "prose dark:prose-invert max-w-none"
    }
  }
}
```

## Citation Display

```typescript
TYPE CitationDisplay = {
  // Inline citation styling
  inline: {
    marker: "text-blue-500 hover:underline cursor-pointer",
    icon: "text-blue-400 text-sm ml-1"
  },

  // Mobile preview & modal
  mobile: {
    preview: {
      container: "fixed bottom-16 inset-x-4 bg-gray-800 rounded-lg p-4 shadow-xl",
      enter: "animate-slide-up",
      exit: "animate-slide-down"
    },
    modal: {
      overlay: "fixed inset-0 bg-black/50 z-50",
      container: "fixed inset-x-0 bottom-0 bg-gray-900 rounded-t-xl z-50",
      handle: "w-12 h-1 bg-gray-600 rounded-full mx-auto my-3",
      content: "px-4 pb-safe overflow-y-auto"
    }
  },

  // Desktop side panel
  desktop: {
    container: "border-l border-gray-800 w-80",
    header: "p-4 border-b border-gray-800",
    content: "p-4 prose dark:prose-invert",
    footer: "p-4 border-t border-gray-800"
  }
}
```

## Interaction Patterns

```typescript
TYPE Interactions = {
  // Mobile gestures
  mobile: {
    bottomSheet: {
      drag: {
        threshold: 50,
        animation: "spring(1, 0.9, 0)",
        snapPoints: ["50vh", "85vh", "0vh"]
      },
      dismiss: {
        velocity: 500,
        distance: "25vh"
      }
    },
    tabs: {
      swipe: {
        threshold: 30,
        animation: "ease-out",
        resistance: 0.2
      }
    }
  },

  // Desktop interactions
  desktop: {
    panel: {
      resize: {
        handle: "w-1 hover:bg-gray-700 cursor-col-resize",
        min: 320,
        max: 480
      },
      collapse: {
        button: "absolute -left-3 top-1/2 transform -translate-y-1/2",
        animation: "slide-x"
      }
    }
  },

  // Common transitions
  transitions: {
    content: {
      enter: "animate-fade-in",
      exit: "animate-fade-out",
      duration: 200
    },
    tab: {
      switch: "transition-all duration-200"
    }
  }
}
```

## Navigation Structure

```typescript
TYPE Navigation = {
  // Mobile navigation
  mobile: {
    menu: {
      button: "fixed left-4 top-4 z-30 rounded-full bg-gray-800 p-2",
      drawer: {
        enter: "slide-in-from-left",
        exit: "slide-out-to-left",
        container: "fixed inset-y-0 left-0 w-80 bg-gray-900 z-40"
      }
    },
    actions: {
      container: "fixed bottom-4 right-4 z-30 flex flex-col gap-2",
      button: "rounded-full bg-gray-800 p-3 shadow-lg"
    }
  },

  // Desktop navigation
  desktop: {
    sidebar: {
      container: "w-64 border-r border-gray-800",
      header: "p-4 border-b border-gray-800",
      content: "overflow-y-auto"
    },
    toolbar: {
      container: "h-12 border-b border-gray-800",
      actions: "flex items-center px-4 gap-4"
    }
  }
}
```

## Responsive Adaptations

```typescript
TYPE ResponsiveUI = {
  // Core breakpoints
  breakpoints: {
    sm: "640px",   // Mobile breakpoint
    lg: "1024px"   // Desktop breakpoint
  },

  // Feature adaptations
  features: {
    steps: {
      mobile: "bottom-sheet with tabs",
      desktop: "side-panel fixed"
    },
    citations: {
      mobile: "modal with preview",
      desktop: "side-panel"
    },
    navigation: {
      mobile: "floating buttons + drawer",
      desktop: "persistent sidebar"
    }
  }
}
```

This comprehensive UI specification provides:
- Mobile-first design with bottom sheets and gestures
- Enhanced desktop experience with side panels
- Smooth transitions between viewports
- Consistent visual hierarchy
- Natural interactions on all devices
- Accessibility across platforms
