# Security Policy

## Supported Versions

Security fixes are released for the latest minor version of Excanon.

| Version | Supported |
| ------- | --------- |
| 0.2.x   | Yes       |
| < 0.2   | No        |

## Reporting a Vulnerability

Please do not report security vulnerabilities through public issues, discussions, or pull requests.

Report them privately through GitHub's private vulnerability reporting:

1. Go to the [Security tab](https://github.com/jmalovera10/excanon/security) of this repository.
2. Click **Report a vulnerability**.
3. Describe the issue, the affected version, and steps to reproduce it.

You should receive an acknowledgement within 7 days. Once the issue is confirmed, a fix is prepared privately and released together with a security advisory. Reporters are credited in the advisory unless they ask not to be.

## Scope Notes

The `call` operation executes Elixir scripts from the path given in a rule. Rules that use `call` must only come from trusted sources. Loading rule definitions from untrusted input with `call` enabled is equivalent to allowing arbitrary code execution, and is not considered a vulnerability in Excanon itself. Reports about ways to escape or bypass that trust boundary are in scope.
