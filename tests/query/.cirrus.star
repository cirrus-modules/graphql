load("../../lib.star", "execute")


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

    return []
