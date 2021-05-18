## Starlark helpers to query [Cirrus CI GraphQL API](https://cirrus-ci.org/api/)

Especially handy for Cirrus CI hooks. Here is an example of a Cirrus hook that will automatically re-run a failed task
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

Here is an example of executing a custom query:


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
