Introduction
Web applications often appear secure but fail to verify if a user is authorized to access specific data. By manipulating object references (URLs, APIs), students learn to detect Insecure Direct Object References (IDOR). This builds analytical skills and highlights the critical difference between input validation and access control.

Context
While testing the CyberBank simulation, Mary discovered that changing an account ID in a request exposed another user's financial data. The system failed to verify ownership. Mary documented this authorization flaw across multiple endpoints, learning that effective security testing identifies weak access controls to protect users before a breach occurs.
