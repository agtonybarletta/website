console.log("Redirecting to the homepage...");

fetch("http://www.agtonybarletta.com/health").then(
    response => {
        if (response.ok) {
            console.log("The website is healthy. Redirecting to the homepage...");
            window.location.href = "http://www.agtonybarletta.com";
        } else {
            console.error("The website is not healthy. Staying on the current page.");
        }
    }
)