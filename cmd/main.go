package main

import (
	"fmt"
	"os"
	"path/filepath"

	"github.com/spf13/cobra"
	"go.uber.org/zap"
)

/*
	I made trash while dozing off.
*/

var (
	// Sugar logger with zap
	logger     *zap.Logger
	ghRepoName string // If make with gh repo

	rootCmd = &cobra.Command{
		Use:   "3dots",
		Short: "A generator for 1eedaegon based development environments",
		Long:  `This CLI is a tool to generate the needed files to quickly create a project structure.`,
	}

	goCmd = &cobra.Command{
		Use:   "go",
		Short: "A generator for Golang project structure",
		Long:  `A generator for Golang project structure`,
		Run: func(cmd *cobra.Command, args []string) {
			generateGoProject(args[0])
		},
	}
	golangProjectDir = []string{
		"api", "cmd", "internal", "pkg",
	}
	// nextjsCmd = &cobra.Command{
	// 	Use:   "next",
	// 	Short: "A generator for NextJS project structure",
	// 	Long:  `A generator for NextJS project structure`,
	// }
)

func main() {
	logger, _ = zap.NewProduction()
	defer logger.Sync()
	if err := rootCmd.Execute(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}

func init() {
	rootCmd.AddCommand(goCmd)
	// rootCmd.PersistentFlags().StringVarP(&ghRepoName, "github", "gh", "", "name of github repository for the create project")
}

func generateGoProject(path string) {
	if path == "" {
		logger.Sugar().Warnf("There is no paths: %s ", path)
		return
	}

	path = ensureTrailingSlash(path)
	if isNotDirectoryExists(path) {
		logger.Sugar().Warnf("Directory not exist: %s", path)
		return
	}
	projectName := getProjectNameFromWd(path)
	for _, subdir := range golangProjectDir {
		mkedDir := path + subdir
		if err := os.MkdirAll(mkedDir, 0755); err != nil {
			panic(err)
		}
		logger.Sugar().Infof("%s created.", mkedDir)
	}
	generateGoMain()
	generateMakefile(path, projectName)
}

func ensureTrailingSlash(path string) string {
	pathLength := len(path)
	if pathLength == 0 {
		return path
	}
	if path[pathLength-1] != '/' {
		return path + "/"
	}
	return path
}

func isNotDirectoryExists(path string) bool {
	if path == "./" {
		abs, err := convertFromDotToAbs(path)
		if err != nil {
			return true
		}
		path = abs
	}

	_, err := os.Stat(path)
	logger.Sugar().Info(path, err)
	if !os.IsExist(err) {
		return false
	}
	return true
}

func generateGoMain() {
	content := `package main
import "fmt"

func main() {
	fmt.Println("Hello, setting!")
}`
	if err := os.WriteFile("./cmd/main.go", []byte(content), 0644); err != nil {
		panic(err)
	}
}

func generateMakefile(path, projectName string) {
	content := fmt.Sprintf(`
.PHONY: install
install:
	go mod tidy

.PHONY: test
test: 
	go test ./... 

.PHONY: build
build:
	go build -o ./bin/%[1]s ./cmd/main.go


.PHONY: run
run: build
	./bin/%[1]s

.PHONY: debug-test
debug-test: 
	cd ./internal/server && go test -v -debug=true
`, projectName)
	if err := os.WriteFile(path+"makefile", []byte(content), 0644); err != nil {
		panic(err)
	}
}

func convertFromDotToAbs(dotPath string) (string, error) {
	absPath, err := filepath.Abs(dotPath)
	if err != nil {
		return "", err
	}
	return absPath, nil
}
func getProjectNameFromWd(path string) string {
	var dirName string
	if path == "./" {
		absPath, err := convertFromDotToAbs(path)
		if err != nil {
			logger.Sugar().Warnf("Error converting to absolute path: %v", err)
			return ""
		}
		dirName = filepath.Base(absPath)
	} else {
		dirName = filepath.Base(path)
		logger.Sugar().Infof("Directory name:", dirName)
	}
	return dirName
}
