package cli

import (
	"fmt"

	"github.com/spf13/cobra"
)

func newVersionCommand(version, commit, date string) *cobra.Command {
	return &cobra.Command{
		Use:   "version",
		Short: "Print version information",
		Run: func(cmd *cobra.Command, args []string) {
			fmt.Printf("spec version %s\n", version)
			if verbose {
				fmt.Printf("commit: %s\n", commit)
				fmt.Printf("built: %s\n", date)
			}
		},
	}
}
