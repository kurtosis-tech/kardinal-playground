from flask import Flask, render_template, request, redirect, url_for
import os
import psycopg2
from urllib.parse import urlparse

app = Flask(__name__)


def get_db_connection():
    connection_string = os.environ["POSTGRES"]
    p = urlparse(connection_string)

    pg_connection_dict = {
        "database": p.path[1:],
        "user": p.username,
        "password": p.password,
        "host": p.hostname,
        "sslmode": "require",
    }

    print(pg_connection_dict)
    return psycopg2.connect(**pg_connection_dict)


def init_db():
    conn = get_db_connection()
    try:
        with conn.cursor() as cur:
            # Create 'votes' table if it doesn't exist
            cur.execute(
                """
                CREATE TABLE IF NOT EXISTS votes (
                    option VARCHAR(20) PRIMARY KEY,
                    count INTEGER DEFAULT 0
                )
            """
            )

            # Initialize vote counts if not present
            cur.execute(
                "INSERT INTO votes (option, count) VALUES ('option1', 0) ON CONFLICT (option) DO NOTHING"
            )
            cur.execute(
                "INSERT INTO votes (option, count) VALUES ('option2', 0) ON CONFLICT (option) DO NOTHING"
            )

            # Only insert option3 if app version is not v1
            if app_version != "v1":
                cur.execute(
                    "INSERT INTO votes (option, count) VALUES ('option3', 0) ON CONFLICT (option) DO NOTHING"
                )

            conn.commit()
    except psycopg2.Error as e:
        print(f"An error occurred while initializing the database: {e}")
        conn.rollback()
    finally:
        conn.close()


# Getting app version
app_version = os.environ.get("APP_VERSION", "v1")
print("app_version is: " + app_version)

# Initialize the database when the app starts
with app.app_context():
    init_db()

option1 = os.environ.get("OPTION1", "Option 1")
option2 = os.environ.get("OPTION2", "Option 2")
option3 = os.environ.get("OPTION3", "Option 3") if app_version != "v1" else None
title = os.environ.get("TITLE", "Vote For Your Favorite Option")


@app.route("/", methods=["GET", "POST"])
def index():
    conn = get_db_connection()
    try:
        if request.method == "POST":
            vote = request.form["vote"]
            with conn.cursor() as cur:
                cur.execute(
                    "UPDATE votes SET count = count + 1 WHERE option = %s", (vote,)
                )
                conn.commit()
            return redirect(url_for("index"))

        # Get current vote counts
        with conn.cursor() as cur:
            cur.execute("SELECT option, count FROM votes")
            votes = dict(cur.fetchall())

        option1_votes = votes.get("option1", 0)
        option2_votes = votes.get("option2", 0)
        option3_votes = votes.get("option3", 0) if app_version != "v1" else None

        if app_version != "v1":
            return render_template(
                "index.html",
                option1_votes=option1_votes,
                option2_votes=option2_votes,
                option3_votes=option3_votes,
                title=title,
                option1=option1,
                option2=option2,
                option3=option3,
            )
        else:
            return render_template(
                "index.html",
                option1_votes=option1_votes,
                option2_votes=option2_votes,
                title=title,
                option1=option1,
                option2=option2,
            )
    except psycopg2.Error as e:
        print(f"An error occurred: {e}")
        return "An error occurred", 500
    finally:
        conn.close()


if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=80)
