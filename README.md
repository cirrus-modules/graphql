## Starlark helpers to query [Cirrus CI GraphQL API](https://cirrus-ci.org/api/)

Especially handy for Cirrus CI hooks. Here is an example of executing a custom query:

```python
# .cirrus.star
load("github.com/cirrus-modules/graphql", "execute")

def main(ctx):
    response = execute(
        """
        query($owner: String!, $name: String!) {
          githubRepository(owner: $owner, name: $name) {
            id
          }
        }""",
        variables={"owner": "cirruslabs", "name": "cirrus-cli"}
    )

    print(response)
```

### Automatically re-running a task

Here is an example of a Cirrus hook that will automatically re-run a failed task
in case of a particular issue found it logs:

```python
# .cirrus.star
load("github.com/cirrus-modules/graphql", "rerun_task_if_issue_in_logs")

def on_task_failed(ctx):
  if ctx.payload.data.task.automaticReRun:
    print("Task is already an automatic re-run! Won't even try to re-run it...")
    return
  rerun_task_if_issue_in_logs(ctx.payload.data.task.id, "Time out")
```

### Generating `CIRRUS_BUILD_NUMBER`

Cirrus CI by default is not generating monotonically increased build numbers because it's impossible to for
repositories with a very high commit rate due to race in webhook deliveries. But for 99.9% of repositories
it's possible to achieve via repository metadata and Starlark configuration:

```python
load("github.com/cirrus-modules/graphql", "generate_build_number")

def main():
  return {
    "env": {
      "CIRRUS_BUILD_NUMBER": generate_build_number()
    }
  }
```
