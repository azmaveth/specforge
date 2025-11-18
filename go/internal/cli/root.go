package cli

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

var (
	cfgFile string
	verbose bool
	quiet   bool
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

	// Bind flags to viper
	viper.BindPFlag("model", cmd.PersistentFlags().Lookup("model"))
	viper.BindPFlag("cache.enabled", cmd.PersistentFlags().Lookup("cache"))
	viper.BindPFlag("cache.ttl", cmd.PersistentFlags().Lookup("cache-ttl"))
	viper.BindPFlag("output.dir", cmd.PersistentFlags().Lookup("output-dir"))

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
	if cfgFile != "" {
		viper.SetConfigFile(cfgFile)
	} else {
		home, err := os.UserHomeDir()
		if err != nil {
			return
		}

		// Search for config in home directory
		viper.AddConfigPath(home + "/.specforge")
		viper.SetConfigName("config")
		viper.SetConfigType("yaml")
	}

	// Read from environment variables
	viper.SetEnvPrefix("SPECFORGE")
	viper.AutomaticEnv()

	// Load .env file if present
	viper.SetConfigFile(".env")
	viper.ReadInConfig() // ignore errors for .env

	// Read config file
	if err := viper.ReadInConfig(); err == nil {
		if verbose {
			fmt.Fprintln(os.Stderr, "Using config file:", viper.ConfigFileUsed())
		}
	}
}
