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
