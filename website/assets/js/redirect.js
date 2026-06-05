console.log("Redirecting to the homepage...");

fetch("https://website.agtonybarletta.it/health").then(
    response => {
        if (response.ok) {
            console.log("The website is healthy. Redirecting to the homepage...");
            window.location.href = "https://website.agtonybarletta.it";
        } else {
            console.error("The website is not healthy. Staying on the current page.");
        }
    }
)