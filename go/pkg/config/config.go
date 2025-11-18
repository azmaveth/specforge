package config

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/spf13/viper"
)

// Config holds all configuration for the application
type Config struct {
	// Default model to use (e.g., "openai:gpt-4", "anthropic:claude-3-5-sonnet")
	DefaultModel string `mapstructure:"default_model"`

	// Provider configurations
	Providers ProviderConfigs `mapstructure:"providers"`

	// Cache configuration
	Cache CacheConfig `mapstructure:"cache"`

	// Output configuration
	Output OutputConfig `mapstructure:"output"`

	// Validation configuration
	Validation ValidationConfig `mapstructure:"validation"`

	// Log configuration
	Log LogConfig `mapstructure:"log"`
}

// ProviderConfigs holds configuration for all LLM providers
type ProviderConfigs struct {
	OpenAI    OpenAIConfig    `mapstructure:"openai"`
	Anthropic AnthropicConfig `mapstructure:"anthropic"`
	Ollama    OllamaConfig    `mapstructure:"ollama"`
	Google    GoogleConfig    `mapstructure:"google"`
}

// OpenAIConfig holds OpenAI-specific configuration
type OpenAIConfig struct {
	APIKey       string        `mapstructure:"api_key"`
	APIKeyEnv    string        `mapstructure:"api_key_env"`
	DefaultModel string        `mapstructure:"default_model"`
	Timeout      time.Duration `mapstructure:"timeout"`
	BaseURL      string        `mapstructure:"base_url"`
}

// AnthropicConfig holds Anthropic-specific configuration
type AnthropicConfig struct {
	APIKey       string        `mapstructure:"api_key"`
	APIKeyEnv    string        `mapstructure:"api_key_env"`
	DefaultModel string        `mapstructure:"default_model"`
	Timeout      time.Duration `mapstructure:"timeout"`
	BaseURL      string        `mapstructure:"base_url"`
}

// OllamaConfig holds Ollama-specific configuration
type OllamaConfig struct {
	Host         string        `mapstructure:"host"`
	DefaultModel string        `mapstructure:"default_model"`
	Timeout      time.Duration `mapstructure:"timeout"`
}

// GoogleConfig holds Google Gemini-specific configuration
type GoogleConfig struct {
	APIKey       string        `mapstructure:"api_key"`
	APIKeyEnv    string        `mapstructure:"api_key_env"`
	DefaultModel string        `mapstructure:"default_model"`
	Timeout      time.Duration `mapstructure:"timeout"`
	BaseURL      string        `mapstructure:"base_url"`
}

// CacheConfig holds cache-related configuration
type CacheConfig struct {
	Backend string        `mapstructure:"backend"` // "mem" or "disk"
	TTL     time.Duration `mapstructure:"ttl"`
	MaxSize string        `mapstructure:"max_size"`
	Enabled bool          `mapstructure:"enabled"`
}

// OutputConfig holds output-related configuration
type OutputConfig struct {
	Dir       string `mapstructure:"dir"`
	Format    string `mapstructure:"format"` // "markdown", "json", "yaml"
	AutoSlice bool   `mapstructure:"auto_slice"`
}

// ValidationConfig holds validation-related configuration
type ValidationConfig struct {
	Enabled  bool `mapstructure:"enabled"`
	MinScore int  `mapstructure:"min_score"`
	Strict   bool `mapstructure:"strict"`
}

// LogConfig holds logging-related configuration
type LogConfig struct {
	Level  string `mapstructure:"level"`  // "debug", "info", "warn", "error"
	Format string `mapstructure:"format"` // "text" or "json"
}

// Load loads configuration from file, environment variables, and defaults
func Load(cfgFile string) (*Config, error) {
	v := viper.New()

	// Set defaults
	setDefaults(v)

	// Load config file if specified
	if cfgFile != "" {
		v.SetConfigFile(cfgFile)
	} else {
		// Search for config in standard locations
		home, err := os.UserHomeDir()
		if err == nil {
			v.AddConfigPath(filepath.Join(home, ".specforge"))
		}
		v.AddConfigPath(".")
		v.SetConfigName("config")
		v.SetConfigType("yaml")
	}

	// Read config file (ignore error if not found)
	if err := v.ReadInConfig(); err != nil {
		if _, ok := err.(viper.ConfigFileNotFoundError); !ok {
			return nil, fmt.Errorf("failed to read config file: %w", err)
		}
	}

	// Load .env file if it exists
	if _, err := os.Stat(".env"); err == nil {
		v.SetConfigFile(".env")
		v.SetConfigType("env")
		v.ReadInConfig() // ignore errors for .env
	}

	// Read from environment variables
	v.SetEnvPrefix("SPECFORGE")
	v.SetEnvKeyReplacer(strings.NewReplacer(".", "_"))
	v.AutomaticEnv()

	// Unmarshal into config struct
	var cfg Config
	if err := v.Unmarshal(&cfg); err != nil {
		return nil, fmt.Errorf("failed to unmarshal config: %w", err)
	}

	// Resolve API keys from environment variables
	if err := resolveAPIKeys(&cfg); err != nil {
		return nil, fmt.Errorf("failed to resolve API keys: %w", err)
	}

	return &cfg, nil
}

// setDefaults sets default configuration values
func setDefaults(v *viper.Viper) {
	// Default model
	v.SetDefault("default_model", "openai")

	// OpenAI defaults
	v.SetDefault("providers.openai.api_key_env", "OPENAI_API_KEY")
	v.SetDefault("providers.openai.default_model", "gpt-4-turbo")
	v.SetDefault("providers.openai.timeout", "30s")
	v.SetDefault("providers.openai.base_url", "https://api.openai.com/v1")

	// Anthropic defaults
	v.SetDefault("providers.anthropic.api_key_env", "ANTHROPIC_API_KEY")
	v.SetDefault("providers.anthropic.default_model", "claude-3-5-sonnet-20241022")
	v.SetDefault("providers.anthropic.timeout", "60s")
	v.SetDefault("providers.anthropic.base_url", "https://api.anthropic.com/v1")

	// Ollama defaults
	v.SetDefault("providers.ollama.host", "http://localhost:11434")
	v.SetDefault("providers.ollama.default_model", "llama3.3")
	v.SetDefault("providers.ollama.timeout", "120s")

	// Google defaults
	v.SetDefault("providers.google.api_key_env", "GOOGLE_API_KEY")
	v.SetDefault("providers.google.default_model", "gemini-1.5-pro")
	v.SetDefault("providers.google.timeout", "30s")
	v.SetDefault("providers.google.base_url", "https://generativelanguage.googleapis.com/v1")

	// Cache defaults
	v.SetDefault("cache.backend", "mem")
	v.SetDefault("cache.ttl", "1h")
	v.SetDefault("cache.max_size", "100MB")
	v.SetDefault("cache.enabled", true)

	// Output defaults
	v.SetDefault("output.dir", "./specs")
	v.SetDefault("output.format", "markdown")
	v.SetDefault("output.auto_slice", false)

	// Validation defaults
	v.SetDefault("validation.enabled", true)
	v.SetDefault("validation.min_score", 70)
	v.SetDefault("validation.strict", false)

	// Log defaults
	v.SetDefault("log.level", "info")
	v.SetDefault("log.format", "text")
}

// resolveAPIKeys resolves API keys from environment variables
func resolveAPIKeys(cfg *Config) error {
	// OpenAI
	if cfg.Providers.OpenAI.APIKey == "" && cfg.Providers.OpenAI.APIKeyEnv != "" {
		cfg.Providers.OpenAI.APIKey = os.Getenv(cfg.Providers.OpenAI.APIKeyEnv)
	}

	// Anthropic
	if cfg.Providers.Anthropic.APIKey == "" && cfg.Providers.Anthropic.APIKeyEnv != "" {
		cfg.Providers.Anthropic.APIKey = os.Getenv(cfg.Providers.Anthropic.APIKeyEnv)
	}

	// Google
	if cfg.Providers.Google.APIKey == "" && cfg.Providers.Google.APIKeyEnv != "" {
		cfg.Providers.Google.APIKey = os.Getenv(cfg.Providers.Google.APIKeyEnv)
	}

	return nil
}

// Validate validates the configuration
func (c *Config) Validate() error {
	// Validate cache backend
	if c.Cache.Backend != "mem" && c.Cache.Backend != "disk" {
		return fmt.Errorf("invalid cache backend: %s (must be 'mem' or 'disk')", c.Cache.Backend)
	}

	// Validate output format
	if c.Output.Format != "markdown" && c.Output.Format != "json" && c.Output.Format != "yaml" {
		return fmt.Errorf("invalid output format: %s (must be 'markdown', 'json', or 'yaml')", c.Output.Format)
	}

	// Validate log level
	validLevels := map[string]bool{"debug": true, "info": true, "warn": true, "error": true}
	if !validLevels[c.Log.Level] {
		return fmt.Errorf("invalid log level: %s (must be 'debug', 'info', 'warn', or 'error')", c.Log.Level)
	}

	return nil
}

// GetProviderAPIKey returns the API key for a given provider
func (c *Config) GetProviderAPIKey(provider string) string {
	switch provider {
	case "openai":
		return c.Providers.OpenAI.APIKey
	case "anthropic":
		return c.Providers.Anthropic.APIKey
	case "google":
		return c.Providers.Google.APIKey
	default:
		return ""
	}
}

// HasProviderAPIKey checks if an API key exists for a provider
func (c *Config) HasProviderAPIKey(provider string) bool {
	return c.GetProviderAPIKey(provider) != ""
}
