from app import app


def test_home_returns_200():
    client = app.test_client()
    response = client.get("/")
    assert response.status_code == 200
    assert b"Flask crashed" in response.data


def test_unknown_route_returns_404():
    client = app.test_client()
    response = client.get("/does-not-exist")
    assert response.status_code == 404
