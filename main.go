package main

import (
	"database/sql"
	"fmt"
	"html/template"
	"log"
	"net/http"
	"os"

	_ "github.com/lib/pq"
)

type UserInfo struct {
	Name    string
	Surname string
}

func getEnv(key, def string) string {
	v := os.Getenv(key)
	if v == "" {
		return def
	}
	return v
}

func main() {
	// Получаем параметры подключения из переменных окружения
	db_host := getEnv("POSTGRES_HOST", "localhost")
	db_port := getEnv("POSTGRES_PORT", "5432")
	db_user := getEnv("POSTGRES_USER", "postgres")
	db_password := getEnv("POSTGRES_PASSWORD", "postgres")
	db_name := getEnv("POSTGRES_DB", "postgres")

	dbURL := fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=disable", db_host, db_port, db_user, db_password, db_name)

	db, err := sql.Open("postgres", dbURL)
	if err != nil {
		log.Fatalf("failed to open db: %v", err)
	}
	defer db.Close()

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		if r.Method == http.MethodPost {
			r.ParseForm()
			name := r.FormValue("name")
			surname := r.FormValue("surname")
			if name == "" || surname == "" {
				http.Error(w, "Name and surname required", http.StatusBadRequest)
				return
			}
			var createdAt string
			err := db.QueryRow("INSERT INTO user_info (name, surname) VALUES ($1, $2) RETURNING created_at", name, surname).Scan(&createdAt)
			if err != nil {
				http.Error(w, "DB error: "+err.Error(), http.StatusInternalServerError)
				return
			}
			fmt.Fprintf(w, "Hello, %s %s!\nВремя регистрации: %s\n\n(Чтобы вернуться, обновите страницу или перейдите по адресу /)", name, surname, createdAt)
			return
		}

		tmpl := `
<!DOCTYPE html>
<html>
<head>
    <title>User Info Form</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .form-container { max-width: 400px; margin: 0 auto; }
        input[type="text"] { width: 100%; padding: 10px; margin: 10px 0; border: 1px solid #ddd; border-radius: 4px; }
        button { background: #007cba; color: white; padding: 10px 20px; border: none; border-radius: 4px; cursor: pointer; }
        button:hover { background: #005a87; }
    </style>
</head>
<body>
    <div class="form-container">
        <h2>Enter Your Name and Surname</h2>
        <form method="POST">
            <label for="name">Name:</label><br>
            <input type="text" id="name" name="name" required><br>
            <label for="surname">Surname:</label><br>
            <input type="text" id="surname" name="surname" required><br><br>
            <button type="submit">Submit</button>
        </form>
    </div>
</body>
</html>`
		t, _ := template.New("form").Parse(tmpl)
		t.Execute(w, nil)
	})

	port := "8080"
	log.Printf("Starting server at http://localhost:%s\n", port)
	log.Fatal(http.ListenAndServe(":"+port, nil))
}
