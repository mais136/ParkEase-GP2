const request = require('supertest');
const app = require('../app');
let token;

beforeAll(async () => {
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
    const url = Uri.parse('http://192.168.1.61:3001/api/spots/list-spots');
    const res = await request(app)
      .get(url)
      .set('Authorization', `Bearer ${token}`);
    expect(res.statusCode).toEqual(200);
    expect(res.body).toBeInstanceOf(Array);
  });

  it('should reserve a parking spot', async () => {
    const url = Uri.parse('http://192.168.1.61:3001/api/spots/reserve-spot');
    const res = await request(app)
      .post(url)
      .set('Authorization', `Bearer ${token}`)
      .send({
        spotId: '1234567890'
      });
    expect(res.statusCode).toEqual(200);
    expect(res.body).toHaveProperty('reservationId');
  });

  it('should return 403 for unauthorized access to admin route', async () => {
    const url = Uri.parse('http://192.168.1.61:3001/api/spots/create-spot');
    const res = await request(app)
      .post(url)
      .set('Authorization', `Bearer ${token}`)
      .send({
        location: 'New Spot Location',
        size: 'medium'
      });
    expect(res.statusCode).toEqual(403); // Assuming only admins can create spots
  });
});
