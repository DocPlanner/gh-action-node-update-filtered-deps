# gh-action-node-update-filtered-deps

Updates Node dependencies and creates a pull request with the changes.

Note: prefer dependabot over this action **once** [dependabot supports grouped pull requests](https://github.com/dependabot/dependabot-core/issues/1190).

## Example usage

```yaml
name: Scheduled dependencies update
on:
  schedule:
    - cron: "0 15 * * 2"
jobs:
  update-deps:
    name: Update Node dependencies
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v2
      - uses: DocPlanner/gh-action-node-update-filtered-deps@v2.1.0
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          NPM_TOKEN: ${{ secrets.NPM_TOKEN }} # NPM token to use when `npm-registry-*` configs are set
        with:
          git-user-name: Test # defaults to 'github-actions[bot]'
          git-user-email: myemail@example.com # defaults to '41898282+github-actions[bot]@users.noreply.github.com'
          package-manager: yarn # defaults to 'npm'
          target-version: minor # defaults to 'latest'
          modules-filter: "@types/*" # defaults to '*'
          reviewers: developers # defaults to not setting reviewers
          commit-message-prefix: fix # defaults 'BOT'
          pull-request-labels: test # defaults to 'dependencies'
          bump-version: patch # defaults to not bumping the package version
          npm-registry-scope: "@thescope" # ignored if not all `npm-registry-*` configs are set
          npm-registry-url: "https://domain/pkgs" # ignored if not all `npm-registry-*` configs are set
          pre-commit-script: npm run build # defaults to not running anything
          working-directory: subdir # defaults to not changing the working directory (the directory where all the actions run)
```
