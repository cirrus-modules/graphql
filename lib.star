load("cirrus", "http", "env")


def failed_instruction(task_id):
    return execute(
        """
        query($taskId: ID!) {
          task(id: $taskId) {
            firstFailedCommand {
              name
              logsTail
            }
          }
        }""",
        variables={"taskId": task_id}
    )["task"]["firstFailedCommand"]


def rerun_task(task_id):
    return execute(
        """
        mutation($taskId: ID!, $mutationId: String!) {
          rerun(input: { 
            taskId: $taskId, 
            clientMutationId: $mutationId
          }) {
            newTask {
              id
            }
          }
        }""",
        variables={"taskId": task_id, "mutationId": "rerun-{}".format(task_id)}
    )["rerun"]["newTask"]["id"]


def rerun_task_if_issue_in_logs(task_id, issue_text):
    """
    Re-runs a task if the failed command's logs contain a particular issue.
    For example, if there are transient network issues that causes request timeouts.
    """
    instruction = failed_instruction(task_id)
    if not instruction or not instruction["logsTail"]:
        return None
    print("Found failed instruction {}! Inspecting logs...".format(instruction["name"]))
    for line in instruction["logsTail"]:
        if issue_text in line:
            print("Failed log line indicating a transient issue!")
            new_task_id = rerun_task(task_id)
            print("Successfully re-ran task! Here is the new one: {}".format(new_task_id))
            return new_task_id
    print("Didn't find any transient issues in logs!")
    return None


def execute(query, variables=None):
    body = {
        "query": query,
        "variables": variables or {}
    }

    headers = {}
    if "CIRRUS_TOKEN" in env:
        headers["Authorization"] = "Bearer " + env["CIRRUS_TOKEN"]

    response = http.post(
        url=env.get("CIRRUS_API_HOST", "https://api.cirrus-ci.com/") + "graphql",
        headers=headers,
        json_body=body
    )

    if response.status_code != 200:
        fail("GraphQL call got bad response code {}".format(response.status))

    jsonResponse = response.json()

    if ("errors" in jsonResponse) and len(jsonResponse["errors"]) > 0:
        fail("GraphQL query returned errors {}".format(jsonResponse["errors"]))

    return jsonResponse["data"]
