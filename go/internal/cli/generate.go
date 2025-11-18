package cli

import (
	"fmt"

	"github.com/spf13/cobra"
)

func newGenerateCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "generate [INPUT]",
		Short: "Generate a specification",
		Long: `Generate a specification from a prompt or file.

Examples:
  # From argument
  spec generate "Implement JWT authentication"

  # From stdin
  echo "Build a blog engine" | spec generate

  # From file
  spec generate --from requirements.txt

  # With specific type and model
  spec generate --type=task --model=anthropic:claude-3-opus "Refactor auth module"

  # Slice output
  spec generate "System design" --type=system --slice --outdir=phases/`,
		RunE: runGenerate,
	}

	cmd.Flags().String("type", "task", "spec type (task, system, plan)")
	cmd.Flags().String("from", "", "read input from file")
	cmd.Flags().String("to", "", "write output to file")
	cmd.Flags().String("template", "", "custom template file")
	cmd.Flags().String("format", "markdown", "output format (markdown, json, yaml)")
	cmd.Flags().Bool("slice", false, "split into logical sections")
	cmd.Flags().String("outdir", "", "output directory (with --slice)")
	cmd.Flags().Bool("no-validate", false, "skip validation")
	cmd.Flags().Bool("no-cache", false, "disable caching for this request")

	return cmd
}

func runGenerate(cmd *cobra.Command, args []string) error {
	// TODO: Implement generate logic
	fmt.Println("Generate command - Coming soon!")
	fmt.Println("This will generate specifications using LLM providers.")

	// For now, just show what would be generated
	if len(args) > 0 {
		fmt.Printf("\nInput: %s\n", args[0])
	}

	specType, _ := cmd.Flags().GetString("type")
	model, _ := cmd.Flags().GetString("model")

	fmt.Printf("Type: %s\n", specType)
	if model != "" {
		fmt.Printf("Model: %s\n", model)
	}

	return nil
}
