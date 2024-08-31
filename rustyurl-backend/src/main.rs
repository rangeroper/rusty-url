use actix_web::{web, App, HttpResponse, HttpServer, Responder};
use aws_sdk_dynamodb::{Client};
use aws_sdk_dynamodb::model::AttributeValue; // Import AttributeValue
use aws_config;
use serde::{Deserialize, Serialize};
use uuid::Uuid;
use std::collections::HashMap;

#[derive(Serialize, Deserialize)]
struct UrlRequest {
    long_url: String,
}

#[derive(Serialize, Deserialize)]
struct UrlResponse {
    short_url: String,
}

async fn shorten_url(data: web::Json<UrlRequest>, client: web::Data<Client>) -> impl Responder {
    let short_url = Uuid::new_v4().to_string(); // Generate a unique short URL
    let long_url = &data.long_url;

    // Create item with explicit AttributeValue types
    let mut item = HashMap::new();
    item.insert("short_url".to_string(), AttributeValue::S(short_url.clone()));
    item.insert("long_url".to_string(), AttributeValue::S(long_url.clone()));

    match client.put_item()
        .table_name("UrlShortener")
        .set_item(Some(item))
        .send()
        .await {
            Ok(_) => HttpResponse::Ok().json(UrlResponse { short_url }),
            Err(err) => {
                eprintln!("Error adding item: {:?}", err);
                HttpResponse::InternalServerError().body("Error shortening URL")
            }
        }
}

async fn redirect(short_url: web::Path<String>, client: web::Data<Client>) -> impl Responder {
    let result = client.get_item()
        .table_name("UrlShortener")
        .key("short_url", AttributeValue::S(short_url.into_inner())) // Use AttributeValue::S for the key
        .send()
        .await;

    match result {
        Ok(output) => {
            if let Some(item) = output.item {
                let long_url = item.get("long_url").unwrap().as_s().unwrap();
                HttpResponse::Found().append_header(("Location", long_url.clone())).finish()
            } else {
                HttpResponse::NotFound().body("URL not found")
            }
        }
        Err(err) => {
            eprintln!("Error retrieving item: {:?}", err);
            HttpResponse::InternalServerError().body("Error fetching URL")
        }
    }
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    let shared_config = aws_config::load_from_env().await;
    let client = Client::new(&shared_config);

    HttpServer::new(move || {
        App::new()
            .app_data(web::Data::new(client.clone()))
            .route("/shorten", web::post().to(shorten_url))
            .route("/{short_url}", web::get().to(redirect))
    })
    .bind("0.0.0.0:8080")?
    .run()
    .await
}
