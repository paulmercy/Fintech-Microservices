package fintech

# Default deny
default allow = false

# Allow user to access their own data
allow {
    input.method == "GET"
    input.path = ["users", user_id]
    input.user.id == to_number(user_id)
}

# Allow user to view their own transactions
allow {
    input.method == "GET"
    input.path = ["transactions", "user", user_id]
    input.user.id == to_number(user_id)
}

# Allow authenticated users to create transactions for themselves
allow {
    input.method == "POST"
    input.path = ["transactions"]
    input.body.user_id == input.user.id
}

# Admin can access all endpoints
allow {
    input.user.role == "admin"
}