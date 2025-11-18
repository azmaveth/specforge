package cli

import (
	"fmt"
	"os"

	"github.com/azmaveth/specforge/pkg/config"
	"github.com/spf13/cobra"
)

var (
	cfgFile string
	verbose bool
	quiet   bool
	cfg     *config.Config
)

// Execute runs the root command
func Execute(version, commit, date string) error {
	rootCmd := newRootCommand(version, commit, date)
	return rootCmd.Execute()
}

func newRootCommand(version, commit, date string) *cobra.Command {
	cmd := &cobra.Command{
		Use:   "spec",
		Short: "A Unix-style specification generator for agentic AI workflows",
		Long: `SpecForge generates high-quality specifications for tasks, systems, and plans.

It's designed to be composable, pipeable, and friendly to both humans and AI agents.

Examples:
  # Generate a task spec
  spec generate "Implement JWT authentication"

  # From stdin
  echo "Build a blog engine" | spec generate

  # Slice a document
  spec transform --slice design.md --outdir=phases/

  # Validate a spec
  spec validate spec.md --lint

For more information, visit: https://github.com/azmaveth/specforge`,
		SilenceUsage: true,
	}

	// Global flags
	cmd.PersistentFlags().StringVar(&cfgFile, "config", "", "config file (default: $HOME/.specforge/config.yaml)")
	cmd.PersistentFlags().String("model", "", "LLM model (e.g., openai:gpt-4)")
	cmd.PersistentFlags().Bool("cache", true, "enable caching")
	cmd.PersistentFlags().String("cache-ttl", "1h", "cache TTL duration")
	cmd.PersistentFlags().String("output-dir", "./specs", "default output directory")
	cmd.PersistentFlags().BoolVarP(&quiet, "quiet", "q", false, "suppress non-essential output")
	cmd.PersistentFlags().BoolVarP(&verbose, "verbose", "v", false, "verbose output")

	// Add subcommands
	cmd.AddCommand(newVersionCommand(version, commit, date))
	cmd.AddCommand(newGenerateCommand())
	// cmd.AddCommand(newTransformCommand())
	// cmd.AddCommand(newValidateCommand())
	// cmd.AddCommand(newCacheCommand())

	// Initialize config
	cobra.OnInitialize(initConfig)

	return cmd
}

func initConfig() {
	// Load configuration
	loadedCfg, err := config.Load(cfgFile)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error loading config: %v\n", err)
		os.Exit(1)
	}

	// Validate configuration
	if err := loadedCfg.Validate(); err != nil {
		fmt.Fprintf(os.Stderr, "Invalid config: %v\n", err)
		os.Exit(1)
	}

	cfg = loadedCfg

	if verbose {
		fmt.Fprintf(os.Stderr, "Config loaded successfully\n")
		fmt.Fprintf(os.Stderr, "Default model: %s\n", cfg.DefaultModel)
		fmt.Fprintf(os.Stderr, "Cache backend: %s\n", cfg.Cache.Backend)
		fmt.Fprintf(os.Stderr, "Output dir: %s\n", cfg.Output.Dir)
	}
}
