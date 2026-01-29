# Repository Guidelines

## Project Structure & Module Organization
- `jdk/` and `jre/` contain the Dockerfiles for the JDK and JRE images.
- `entrypoint.sh` handles CA certificate updates at container start.
- `src/hello-world/` is used by CI smoke tests.
- `README.md` documents usage; `VERSION.md` tracks releases.
- CI/CD is defined in `.drone.yml`.

## Build, Test, and Development Commands
- Build JDK:
  ```sh
  docker build -t kernel528/jdk:jdk-latest -f jdk/Dockerfile .
  ```
- Build JRE:
  ```sh
  docker build -t kernel528/jre:jre-latest -f jre/Dockerfile .
  ```
- Local smoke test:
  ```sh
  docker run --rm kernel528/jdk:jdk-latest java -version
  docker run --rm kernel528/jre:jre-latest java -version
  ```

## Coding Style & Naming Conventions
- Keep Dockerfiles aligned with the Adoptium alpine templates referenced in `README.md`.
- Update `JAVA_VERSION`, binary URLs, and SHA256 checksums together.
- Prefer explicit tags (avoid `latest` in docs unless required).

## Testing Guidelines
- CI compiles and runs `src/hello-world/HelloWorld.java` using the JDK, then runs it with the JRE.
- If you change `entrypoint.sh` or CA logic, verify it still updates certificates and exits cleanly.

## Commit & Pull Request Guidelines
- Commit messages are short and descriptive (e.g., “Update to temurin 25.0.1+8.”).
- Use versioned branches (e.g., `25.x`) and update `VERSION.md` and `README.md` with new tags.
- PRs should keep `.drone.yml` tags in sync with image tags.

## Security & Configuration Tips
- GPG key import is required for verifying Adoptium releases; keep key IDs current.
- Checksums must match the downloaded artifacts for both JDK and JRE.
