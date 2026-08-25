import os
import sys
from github import Github
from github import Auth

env_name = sys.argv[1].upper()
status_text = sys.argv[2]

auth = Auth.Token(os.getenv("GITHUB_TOKEN"))
g = Github(auth=auth)
repo = g.get_repo(os.getenv("GITHUB_REPOSITORY"))

commit_sha = os.getenv("GITHUB_SHA")
commit = repo.get_commit(commit_sha)
pulls = commit.get_pulls()

for pr in pulls:
    print(f"Updating status for PR #{pr.number} -> {env_name}: {status_text}")
    comments = pr.get_issue_comments()
    target_comment = None
    
    for comment in comments:
        if "## 📊 SQLMesh Impact Report" in comment.body:
            target_comment = comment
            break
            
    if target_comment:
        body = target_comment.body
        
        if "### 🚀 Deployment Status" not in body:
            body += "\n\n---\n### 🚀 Deployment Status\n* **DEV:** ⏳ Pending\n* **UAT:** ⏳ Pending\n* **PROD:** ⏳ Pending"
            
        body = body.replace(f"* **{env_name}:** ⏳ Pending", f"* **{env_name}:** {status_text}")
        body = body.replace(f"* **{env_name}:** ✅ Deployed", f"* **{env_name}:** {status_text}")
        body = body.replace(f"* **{env_name}:** 🚀 Deployed & Testing", f"* **{env_name}:** {status_text}")
        body = body.replace(f"* **{env_name}:** 🟢 Live in Production", f"* **{env_name}:** {status_text}")
        
        target_comment.edit(body)
        print("PR comment status updated successfully.")