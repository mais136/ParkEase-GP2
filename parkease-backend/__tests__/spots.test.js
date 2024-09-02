const request = require('supertest');
const app = require('../app');
let token;

beforeAll(async () => {
  // Assume you have an endpoint to login and get a token
  const res = await request(app)
    .post('/api/auth/login')
    .send({
      phone: '1234567890',
      password: 'Test@1234'
    });
  token = res.body.token;
});

describe('Parking Spots Endpoints', () => {
  it('should list parking spots', async () => {
    const res = await request(app)
      .get('/api/spots/list-spots')
      .set('Authorization', `Bearer ${token}`);
    expect(res.statusCode).toEqual(200);
    expect(res.body).toBeInstanceOf(Array);
  });

  it('should reserve a parking spot', async () => {
    const res = await request(app)
      .post('/api/spots/reserve-spot')
      .set('Authorization', `Bearer ${token}`)
      .send({
        spotId: '1234567890'
      });
    expect(res.statusCode).toEqual(200);
    expect(res.body).toHaveProperty('reservationId');
  });

  it('should return 403 for unauthorized access to admin route', async () => {
    const res = await request(app)
      .post('/api/spots/create-spot')
      .set('Authorization', `Bearer ${token}`)
      .send({
        location: 'New Spot Location',
        size: 'medium'
      });
    expect(res.statusCode).toEqual(403); // Assuming only admins can create spots
  });
});
