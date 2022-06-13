var redirect_mapping = ${redirect_mapping};

function handler(event) {
  return {
    statusCode: 302,
    statusDescription: 'Found',
    headers: {
      'location': {value: redirect_mapping[event.request.headers.host.value]}
    }
  };
}
