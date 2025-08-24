let
  home-media-user-ed25519 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIManVcKWQ9IZCy7Kge/CgHg4ER07TAEPnvOuSiQMKupS";
  home-media-user-rsa = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC5PieeZRD8Dbsab1V5cqUH8d9J+mP4vCLYL4apM8AH1rgXlfaDARtI61YXm9bd+IM+XUxTUnnGO/Seu/y6lvr41xyLrseAPMOpWVYRMbtdo2nCYZjYCKf8XRPoeheiJBZ8VVwHxMNuXeFaQccHkwB515mrXqgxOh/qAioi4quDg2WotT2QIPWuGBIqnMB7IaEvFJK1fCNMmCRskYn2DNt3R3lrgj6T+mNemf8NFeJ4t8AYnFOv2LqBhvT5MeI5lU5GpdPv6211DQy45MeQUTGCw91YMEi3f76zz6VikCEGeSXESnoZUcxXUXclqSkGHfmoDQxr8i0H8ZQKJZhpRmHxBBTe8x8gQJUAUjFOJULFnjewL66HzpZONN/pRE2JfZcYgnGxxmZ9OznNvpn97meQrMhsc43MEqGg2rrSAvBQdMuPGVkIFKr2cXochmSEIj0/idynyaZlMJgVWRrrLtep1Hy9Q91SHYZb+KMscBcDFGw71lzcHF+tGICs++523Ms=";
  home-media-user-keys = [
    home-media-user-ed25519
    home-media-user-rsa
  ];

  home-media-system-ed25519 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPYALV0x6If58isPYKWvxsPoYPbBagPE9HAN360didH8";
  home-media-system-rsa = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCoRE55TqhIzpB9nCIXHtak1Nzmw4UrGtRwyD9hF8JDuFhJl6YQ5n+SZXOeGTupDsdcu01tNTrfhl2WSnWHJcKzdUVxfT/+7RiiE4VTRV9phpLaaTJwsb7xHDm/J7f9mclamf8ZqAHU/dWRJ/7y0/9PlUUocXYcgoa6QEe8plki8zo2z3s2WNOFIZPRQJ7XBXh9n3I19XmN05+VsMhOASAWUIPETsVDU5dNV5OmWQbErBYDNPNwXw44XFXiN2BcuxmXRYq90x/oa+vLz9vqaJhx3XA3CFqGdWvkf3I/D4rq/Hu+v6FnF3WIZJOgegcHFcmTlVWowhs5oqXzI9NeahFW+tmJMCuq7rfyHQs6ny1zU/euTd30t45ItWip7+97b1DjXU7k50fXbRknu0T5Aq/nSagYH8+1p4GuYL8/7Pygcm/Dx47qa7Tp03AltiHUuuDWsBgCLI8P+xnQ2n41e/Gtn6ZOGQ8rtbK+D2W3h+AriC+tWZIfpZ2KGqaVy2G450cqP/ixgJFoh+MpZluCaUdStDDc5tAZPmBHYeLtDoLz6n3waxSbBTI4TwUT9zj4buL8DSzGNUngc/sXJeqp6RhKKrbAzigVBMWf5yCszPwkRpNQq+qx9oTbggYw9nXrDUVja8M2n7yDUiHrMuNY9YDlGmsQxn1Lu/vbc+9aVg5enQ==";
  home-media-system-keys = [
    home-media-system-ed25519
    home-media-system-rsa
  ];
  home-media-keys = home-media-system-keys ++ home-media-user-keys;

  user-home-desktop-ed25519 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB2wVTZEDwBCIvmTEiKj3pUmhOR+W9qknzbVTXhM25h6";
  user-home-desktop-rsa = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC5S21/xsJ1FVhZydkl0zMiqcZUQrbPv07rhL1INIrm6J4DdaytzBTJEOzLa/CnDRaABTGnuIYOuLJ1dxTBTxuDDtUJex/totmJKxaSQdRbTRFeEq/wY3Y8eG9E2ELpmQTsEyKUNFIrCPmWBHwRCl7UrzSOoAwPSxC5trGbYeI/hvaY0ejn3xawXWEyXHhIYzsv38X903AQIPy0++hICJ58xnTZ4eRy2dDw9KkH9PB5zCc1QPt7VNq2oedOra8KpamTokubW2Q5k1fInSBU0/mhKAz/FYnpR+mhacoK5FuKcPCfcHSoJo2wzctWt93Ekm4/+lrxV6vj/XBjDmDsWC4BErIw0v8+4UMszUKOQBplEz4zAzYnuG6vttoDwKYw5JY9hpzswsc/2WUzQ4o3vMMtLSoQZ2JtMdO5NeWHAL20cnrLS+8joARQ0hw9RoypSDRWa6VwBwoOVjg7tZNf8agnB1Ga1hqBaAw6TqXxfX+KvQDfiET5Awgi3dc4MqrVSJU=";

  rdatar-desktop = [
    user-home-desktop-ed25519
    user-home-desktop-ed25519
  ];
  system-home-desktop-ed25519 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM5/7vjy8In4IdpDP4gbjIyGxxuSPvoSq5QIK+tVhWcA";
  system-home-desktop-rsa = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCSoceydlCm1iwDOc8xkrSUxYjAn6twMr4svXim3pjWtW1+oid5pl2i/DGvdMvfqK8WVqpqJQcV5LDd77U0PyAmHsy0/XXS2ndK6izGr6s99UpTF+MVQ7uQLkaJiH+n9hvH17tWv24wP4qXdLsbcwkQD9S4ex65XmJBXPPfeM9h69USIT7PwffAeCqgdB4UB7qp1cLcavboBZCJazL6B7jvvINUiA6sLuO7L9/zJpetpEJKG0wiVtrWZ1O4bNF34SprhNsmAxn5f9hWX+Q81EsT3yFFCucstST3mGJ+5gBOmpJBqQzEYt5gMZzqazsgjODPQvfiuWK7kEVCT1wE/aX820Dgfpvc/MhNee2PdSvR/YxoG0tzxac4IXLPbKl/4dp7sKlhF/849ojFAWwnS+VjFfnOfet+GIg2en8wc7n5c+ZE3Y3cePYkaEsG+S/+543BCutN1XdOBd1jYWL+y5LzNW/5VOowjLDy0C9MiZn7ykhyLahYAsP8MTKKLmD4O7Vdxzas6cOzxZD7BwZxJVCtmWKCslhpDJSouvuBczzxP5m5w67ThSlqB0gJPJHPXfiJt5wL5wWYLEjWM2OYwJjUvV6GZkJB4v18LTb4H/EAwWRusluIDnqovBAmY4HaIRnrok9NDImFq2QcaW7scfCU+Ym6G0cGTWorz1FcMJYIUQ==";
  home-desktop = [
    system-home-desktop-ed25519
    system-home-desktop-rsa
  ];
in {
  "smbcredentials.age".publicKeys = rdatar-desktop ++ home-desktop;
  "AirVPN-America-WG.conf.age".publicKeys = home-media-keys;
  "transmissioncreds.json.age".publicKeys = home-media-keys;
  "transmissionPwd.age".publicKeys = home-media-keys;
  "sonarrApiKey.age".publicKeys = home-media-keys;
  "radarrApiKey.age".publicKeys = home-media-keys;
  "prowlarrApiKey.age".publicKeys = home-media-keys;
  "bazarrApiKey.age".publicKeys = home-media-keys;
  "jellyfinApiKey.age".publicKeys = home-media-keys;
  "jellyseerrApiKey.age".publicKeys = home-media-keys;
  "truenasApiKey.age".publicKeys = home-media-keys;
  "opnsenseUser.age".publicKeys = home-media-keys;
  "opnsensePass.age".publicKeys = home-media-keys;
  "adguardPass.age".publicKeys = home-media-keys;
}
