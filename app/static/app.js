document.addEventListener('DOMContentLoaded', function () {
  const refreshBtn = document.getElementById('refreshBtn');
  const healthBtn = document.getElementById('healthBtn');
  const greetForm = document.getElementById('greetForm');

  refreshBtn && refreshBtn.addEventListener('click', function () {
    axios.get('/api/info').then(function (resp) {
      document.getElementById('message').textContent = resp.data.message;
      document.getElementById('version').textContent = resp.data.version;
    }).catch(function (err) {
      console.error(err);
      alert('Failed to fetch info');
    });
  });

  healthBtn && healthBtn.addEventListener('click', function () {
    axios.get('/healthz').then(function () {
      const el = document.getElementById('healthStatus');
      el.textContent = 'OK';
      el.classList.remove('fail');
      el.classList.add('ok');
    }).catch(function () {
      const el = document.getElementById('healthStatus');
      el.textContent = 'FAIL';
      el.classList.remove('ok');
      el.classList.add('fail');
    });
  });

  greetForm && greetForm.addEventListener('submit', function (e) {
    e.preventDefault();
    const name = document.getElementById('nameInput').value || 'visitor';
    axios.post('/api/greet', { name: name }).then(function (resp) {
      document.getElementById('greetResult').innerHTML = '<div class="alert alert-success">' + resp.data.greeting + '</div>';
    }).catch(function () {
      document.getElementById('greetResult').innerHTML = '<div class="alert alert-danger">Failed to get greeting</div>';
    });
  });

});
